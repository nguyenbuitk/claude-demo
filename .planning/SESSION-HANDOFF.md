# Session Handoff — Phase 5 Terraform IaC (Rewrite)

**Ngày:** 2026-03-28
**Branch:** `gsd/phase-05-terraform-iac`

---

## Mục tiêu

Học Terraform bằng cách viết lại từng module từ đầu (thay vì dùng code cũ).
Tên project mới: **project-1** (thay vì claude-demo).

---

## Trạng thái hiện tại

| Module | Resources | Status |
|--------|-----------|--------|
| provider.tf + backend | S3 state | ✅ Done |
| module.vpc | 17 resources | ✅ Done + Applied |
| module.ecr | — | ⬜ Chưa viết |
| module.iam | — | ⬜ Chưa viết |
| module.rds | — | ⬜ Chưa viết |
| module.alb | — | ⬜ Chưa viết |
| module.ecs | — | ⬜ Chưa viết |

**Terraform state:** S3 `claude-demo-terraform-state-028668155772/project-1/terraform.tfstate`
**Resources đang chạy trên AWS:** 17 (toàn bộ là VPC module)

---

## Cấu trúc file hiện tại

```
infra/
├── provider.tf              — AWS provider ~> 5.0, S3 backend (key: project-1/terraform.tfstate)
├── main.tf                  — gọi module "vpc"
└── modules/
    └── vpc/
        ├── main.tf          — VPC, subnets, IGW, NAT, route tables, 3 SGs
        ├── variables.tf     — app_name, env
        └── output.tf        — vpc_id, public_subnet_ids, private_subnet_ids, alb_sg_id, ecs_sg_id, rds_sg_id
```

**Không có** terraform.tfvars (hardcode trong main.tf).
**Không có** variables.tf ở root (app_name="project-1", env="dev" truyền thẳng).

---

## VPC đã tạo (10.1.0.0/16)

| Resource | Detail |
|----------|--------|
| VPC | vpc-0c07832e8727ab4d1 / 10.1.0.0/16 |
| Public subnet 1a | subnet-0012fcb231b5adba4 / 10.1.1.0/24 |
| Public subnet 1b | subnet-023e2ffd2ef5ac73b / 10.1.2.0/24 |
| Private subnet 1a | subnet-0368dcab45f53246b / 10.1.10.0/24 |
| Private subnet 1b | subnet-0acc6a1a975e3bdec / 10.1.11.0/24 |
| Internet Gateway | igw-0d8d7ddda2ff5d7d7 |
| NAT Gateway | nat-0995b11a6c24ca61c |
| ALB SG | sg-0cd16df280726208a (port 80 from 0.0.0.0/0) |
| ECS SG | port 5000 from ALB SG |
| RDS SG | port 5432 from ECS SG |

---

## Bước tiếp theo — thứ tự viết các module

Quy tắc: **tự viết code**, tôi chỉ hướng dẫn. Sau mỗi module: `terraform plan` → review → `terraform apply`.

### Bước 1: module.ecr

Tạo folder `infra/modules/ecr/` với 3 files: `main.tf`, `variables.tf`, `output.tf`.

ECR cần tạo:
- `aws_ecr_repository` — repo lưu Docker image
- `aws_ecr_lifecycle_policy` — giữ tối đa 10 images, xóa cũ hơn

Thêm vào `infra/main.tf`:
```hcl
module "ecr" {
  source   = "./modules/ecr"
  app_name = "project-1"
}
```

### Bước 2: module.iam

Tạo folder `infra/modules/iam/` với 3 files.

IAM cần tạo:
- `aws_iam_role` — ecsTaskExecutionRole (để ECS pull image, lấy secrets)
- `aws_iam_role_policy_attachment` — gắn AmazonECSTaskExecutionRolePolicy
- `aws_iam_openid_connect_provider` — GitHub OIDC provider
- `aws_iam_role` — github-actions role (để CI/CD push ECR, deploy ECS)
- `aws_iam_role_policy` — policy cho github-actions role

### Bước 3: module.rds

Tạo folder `infra/modules/rds/` với 3 files.

RDS cần tạo:
- `aws_db_subnet_group` — subnet group dùng private subnets
- `aws_db_instance` — PostgreSQL 17, db.t3.micro, encrypted
- `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` — lưu DB credentials

Input cần từ module khác: `private_subnet_ids`, `rds_sg_id` (từ module.vpc)

### Bước 4: module.alb

Tạo folder `infra/modules/alb/` với 3 files.

ALB cần tạo:
- `aws_lb` — public ALB
- `aws_lb_target_group` — target_type = "ip" (vì Fargate dùng awsvpc)
- `aws_lb_listener` — port 80 → forward đến target group

Input cần: `vpc_id`, `public_subnet_ids`, `alb_sg_id` (từ module.vpc)

### Bước 5: module.ecs

Tạo folder `infra/modules/ecs/` với 3 files.

ECS cần tạo:
- `aws_ecs_cluster`
- `aws_cloudwatch_log_group` — `/ecs/project-1`
- `aws_ecs_task_definition` — Fargate, awsvpc, image từ ECR
- `aws_ecs_service` — desired_count=1, gắn ALB target group

Input cần: nhiều nhất — subnet, SG, role ARN, ECR URL, DB host, secret ARN

---

## Setup trên máy mới

### 1. Kiểm tra SSL cert (corporate proxy)
```bash
ls /tmp/combined-ca.pem && echo "OK" || echo "MISSING"

# Nếu MISSING:
echo "" | openssl s_client -connect registry.terraform.io:443 -showcerts 2>/dev/null \
  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > /tmp/proxy-ca.pem
cat /etc/ssl/certs/ca-certificates.crt /tmp/proxy-ca.pem > /tmp/combined-ca.pem
```

### 2. terraform init
```bash
SSL_CERT_FILE=/tmp/combined-ca.pem terraform -chdir=~/own-repos/claude-demo/infra init
```

### 3. Kiểm tra state
```bash
terraform -chdir=~/own-repos/claude-demo/infra state list
# Phải thấy 17 resources của module.vpc
```

---

## Context quan trọng

- **Không dùng** SSL_CERT_FILE thì terraform lỗi SSL (corporate proxy)
- **Git push** cần: `GIT_SSL_NO_VERIFY=true git push origin <branch>`
- **VPC cũ** (VMo, 10.0.0.0/16) vẫn còn trên AWS — có EC2 bootstrap ở đó, không xóa
- **project-1 VPC** dùng 10.1.0.0/16 để tránh overlap
- User tự viết code, chỉ hỏi khi cần giải thích hoặc bị lỗi
