# AWS Resources — Cost & Management Guide

**Account:** `028668155772` | **Region:** `ap-southeast-1` (Singapore)
**Updated:** 2026-03-26

---

## Resource Inventory

### EC2 Instances

| Name | ID | Type | State | Private IP | Public IP |
|------|----|------|-------|------------|-----------|
| bootstrap-vmo | i-02c2f43c72ffffcd7 | t3.medium | **running** | 10.0.1.18 | 47.129.230.88 (dynamic) |
| bootstrap | i-0c82182b9a67b38a5 | t3.medium | stopped | 172.31.47.141 | — |
| public1 | i-056ebf5458262b863 | t3.micro | stopped | 10.0.1.7 | — |
| private1 | i-09488a004f1bd2f69 | t3.micro | stopped | 10.0.10.40 | — |

> `bootstrap-vmo` nằm trong VPC VMo (private subnet public-1a).
> `bootstrap` và `public1`, `private1` là các EC2 cũ — không cần thiết cho Phase 4+.

### RDS

| Name | ID | Class | Engine | Status | Endpoint |
|------|----|-------|--------|--------|----------|
| claude-demo-db | claude-demo-db | db.t3.micro | PostgreSQL 17.6 | **available** | claude-demo-db.cdouj2djsuhw.ap-southeast-1.rds.amazonaws.com |

- Storage: 20 GB gp2 | Single-AZ | Private subnet

### ECS Fargate

| Resource | Detail |
|----------|--------|
| Cluster | `claude-demo` |
| Service | `claude-demo-svc` — desired: 1, running: 1 |
| Task Definition | `claude-demo:5` — 0.25 vCPU / 512 MB |
| Launch Type | Fargate (serverless — không tốn EC2) |

### ALB (Application Load Balancer)

| Name | DNS | State |
|------|-----|-------|
| claude-demo-alb | claude-demo-alb-2024146360.ap-southeast-1.elb.amazonaws.com | active |

- Internet-facing, 2 EIPs gắn vào 2 subnet AZ khác nhau

### NAT Gateway

| ID | State | Subnet | EIP |
|----|-------|--------|-----|
| nat-0b7e3dc077a811f5c | **available** | vmo-public-1a | 47.131.109.34 |

> ECS task trong private subnet cần NAT để pull image từ ECR.

### Elastic IPs

| IP | Gắn vào | Charge |
|----|---------|--------|
| 46.137.229.66 | ALB ENI (AZ-a) | $0 (đang dùng) |
| 47.131.109.34 | NAT Gateway | $0 (đang dùng) |
| 47.131.149.50 | ALB ENI (AZ-b) | $0 (đang dùng) |

### EBS Volumes (tính phí dù instance stopped)

| Volume ID | Size | Gắn vào | $/tháng |
|-----------|------|---------|---------|
| vol-0200d90bc43d879d6 | 20 GB gp3 | bootstrap-vmo | $1.92 |
| vol-08d78f1219a7f8fd9 | 20 GB gp3 | bootstrap | $1.92 |
| vol-081201bc16061d866 | 8 GB gp3 | public1 | $0.77 |
| vol-01c71cf4c77451b13 | 8 GB gp3 | private1 | $0.77 |

### Secrets Manager

| Name | Rotation |
|------|----------|
| claude-demo/db-password | manual |
| rds!db-2d340a22-95f2-4b24-905a-f1c37ba4e82d | auto (7 ngày) |

---

## Chi Phí Ước Tính / Ngày

> Giá Singapore (ap-southeast-1), on-demand Linux, 2026-03

| Dịch vụ | Resource | $/hr | $/ngày | Ghi chú |
|---------|----------|------|--------|---------|
| EC2 Compute | bootstrap-vmo (t3.medium, **running**) | $0.0496 | **$1.19** | Dừng ngay nếu không dùng |
| EC2 Compute | bootstrap / public1 / private1 (stopped) | $0 | $0 | — |
| EBS Storage | 4 volumes, 56 GB gp3 | — | **$0.18** | Luôn tính dù instance tắt |
| RDS Compute | claude-demo-db (db.t3.micro) | $0.026 | **$0.62** | Stop được khi không dùng |
| RDS Storage | 20 GB gp2 | — | **$0.09** | Luôn tính dù DB stopped |
| NAT Gateway | nat-0b7e3dc077a811f5c | $0.059 | **$1.42** | Chi phí lớn nhất sau EC2 |
| ALB | claude-demo-alb | $0.0225 | **$0.54** | Tính theo giờ |
| ECS Fargate | 1 task (0.25 vCPU / 512 MB) | — | **$0.34** | Dừng = scale service về 0 |
| Secrets Manager | 2 secrets | — | **$0.03** | Không đáng kể |
| ECR | image storage ~200MB | — | **~$0.01** | Không đáng kể |
| **TỔNG HIỆN TẠI** | | | **~$4.42/ngày** | **~$133/tháng** |

---

## Kịch Bản Chi Phí

### Scenario A — Đang phát triển (hiện tại)
Tất cả services running → **~$4.42/ngày**

### Scenario B — Sau Phase 4, chỉ giữ infra chạy
Dừng `bootstrap-vmo` EC2 (không cần nữa):

```bash
aws ec2 stop-instances --instance-ids i-02c2f43c72ffffcd7
```

→ Tiết kiệm $1.19/ngày → **~$3.23/ngày**

### Scenario C — Tạm dừng (không test, giữ ECS + RDS)
Khi không cần truy cập app, xóa NAT + ALB (ECS vẫn running nhưng không public):

> ⚠️ Xóa NAT trước khi ALB vì ECS task cần NAT để deregister gracefully

```bash
# 1. Xóa NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id nat-0b7e3dc077a811f5c

# 2. Delete ALB (sau khi không cần public access)
aws elbv2 delete-load-balancer \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
    --names claude-demo-alb \
    --query "LoadBalancers[0].LoadBalancerArn" --output text)

# 3. Dừng bootstrap-vmo
aws ec2 stop-instances --instance-ids i-02c2f43c72ffffcd7
```

→ Tiết kiệm $1.19 (EC2) + $1.42 (NAT) + $0.54 (ALB) = $3.15/ngày → **~$1.27/ngày**

### Scenario D — Tiết kiệm tối đa (giữ data, tắt compute)
Scale ECS về 0 + Stop RDS + xóa NAT + ALB:

```bash
# Scale ECS về 0 task
aws ecs update-service --cluster claude-demo --service claude-demo-svc --desired-count 0

# Stop RDS (giữ data, chỉ tính storage $0.09/ngày)
aws rds stop-db-instance --db-instance-identifier claude-demo-db

# Xóa NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id nat-0b7e3dc077a811f5c

# Xóa ALB
aws elbv2 delete-load-balancer \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
    --names claude-demo-alb \
    --query "LoadBalancers[0].LoadBalancerArn" --output text)

# Stop EC2 bootstrap-vmo
aws ec2 stop-instances --instance-ids i-02c2f43c72ffffcd7
```

→ Chỉ còn: EBS ($0.18) + RDS storage ($0.09) + Secrets ($0.03) = **~$0.30/ngày**

---

## Khởi Động Lại (Resume Phase 5 Development)

Khi tiếp tục làm việc sau Scenario C hoặc D:

```bash
# 1. Start RDS (nếu đã stop)
aws rds start-db-instance --db-instance-identifier claude-demo-db

# 2. Tạo lại NAT Gateway (ECS Fargate cần NAT để pull image ECR)
# Tạo qua Console: VPC → NAT Gateways → Create
# Subnet: vmo-public-1a (subnet-0cf9522c9c38535bd)
# EIP: tạo mới hoặc dùng 47.131.109.34 (eipalloc-07b05a4db6dd3f969)

# 3. Update route table vmo-private-rt sau khi có NAT ID mới
aws ec2 replace-route \
  --route-table-id <vmo-private-rt-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id <new-nat-id>

# 4. Tạo lại ALB (nếu đã xóa) — làm qua Console
# EC2 → Load Balancers → Create → Application

# 5. Scale ECS service trở lại
aws ecs update-service --cluster claude-demo --service claude-demo-svc --desired-count 1

# 6. Start bootstrap-vmo (nếu cần SSH debug)
aws ec2 start-instances --instance-ids i-02c2f43c72ffffcd7
```

> ⏱️ RDS mất ~3-5 phút start | ECS task mất ~1-2 phút pull image + healthy

---

## Bảng Tóm Tắt Chi Phí

| Scenario | Mô tả | $/ngày | $/tháng |
|----------|-------|--------|---------|
| A — Hiện tại (full) | Tất cả running | ~$4.42 | ~$133 |
| B — Dừng EC2 | Stop bootstrap-vmo | ~$3.23 | ~$97 |
| C — Tạm dừng | Không NAT + ALB, giữ ECS+RDS | ~$1.27 | ~$38 |
| D — Tối thiểu | Chỉ giữ data (RDS stopped) | ~$0.30 | ~$9 |

---

## Routine Hàng Ngày (Practice Project)

> ALB **giữ lại** mỗi ngày — DNS thay đổi mỗi lần tạo, mất công cấu hình lại.
> NAT Gateway **xóa + tạo lại** mỗi ngày — tiết kiệm $1.42/ngày, tạo lại chỉ mất ~60 giây.

**Chi phí qua đêm sau khi stop: ~$0.84/ngày**
= ALB ($0.54) + EBS ($0.18) + RDS storage ($0.09) + Secrets ($0.03)

### Cuối ngày — Stop

```bash
echo "1. Xóa NAT Gateway..." && \
aws ec2 delete-nat-gateway --nat-gateway-id nat-0b7e3dc077a811f5c && \
echo "2. Stop EC2 bootstrap-vmo..." && \
aws ec2 stop-instances --instance-ids i-02c2f43c72ffffcd7 && \
echo "3. Stop RDS..." && \
aws rds stop-db-instance --db-instance-identifier claude-demo-db && \
echo "4. Scale ECS về 0..." && \
aws ecs update-service --cluster claude-demo --service claude-demo-svc --desired-count 0 && \
echo "Done! Chi phi con lai: ~\$0.84/ngay"
```

> ⚠️ Sau khi xóa NAT, cập nhật NAT ID mới vào script resume bên dưới.

### Sáng hôm sau — Resume

```bash
# Lấy route table private
PRIVATE_RT=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=vmo-private-rt" \
  --query "RouteTables[0].RouteTableId" --output text)

# Tạo NAT mới
echo "1. Tạo NAT Gateway..." && \
NAT_ID=$(aws ec2 create-nat-gateway \
  --subnet-id subnet-0cf9522c9c38535bd \
  --allocation-id eipalloc-07b05a4db6dd3f969 \
  --query "NatGateway.NatGatewayId" --output text) && \
echo "NAT ID: $NAT_ID — doi available..." && \
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_ID && \

# Update route table private subnet
echo "2. Update route table..." && \
aws ec2 replace-route \
  --route-table-id $PRIVATE_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_ID && \

# Start các service khác
echo "3. Start RDS..." && \
aws rds start-db-instance --db-instance-identifier claude-demo-db && \
echo "4. Start EC2..." && \
aws ec2 start-instances --instance-ids i-02c2f43c72ffffcd7 && \
echo "5. Scale ECS len 1..." && \
aws ecs update-service --cluster claude-demo --service claude-demo-svc --desired-count 1 && \
echo "Done! Doi ~3-5 phut de RDS va ECS san sang."
```

> ⏱️ Thứ tự khởi động: NAT (~60s) → RDS (~3-5 phút) → ECS pull image → healthy
> RDS cần available trước khi ECS task start (task cần kết nối DB để health check pass)

---

## Lưu Ý Quan Trọng

- **EBS luôn tính tiền** dù instance stopped. Xóa EBS nếu không cần instance `bootstrap` / `public1` / `private1` cũ.
- **NAT Gateway tốn $1.42/ngày** — nên xóa khi không dùng, tạo lại khi cần.
- **ALB tốn $0.54/ngày** — tạo lại ALB mất ~2 phút nhưng DNS name sẽ thay đổi.
- **RDS không xóa** — data mất. Chỉ `stop` (tối đa 7 ngày AWS tự start lại).
- **ECS Fargate** không tốn khi scale về 0 task.
- **Secrets Manager** không xóa — ECS task cần để lấy DB password.
