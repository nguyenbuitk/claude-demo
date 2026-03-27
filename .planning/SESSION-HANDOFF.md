# Session Handoff — Phase 5 Terraform IaC

**Ngày:** 2026-03-27
**Branch:** `gsd/phase-05-terraform-iac` (up to date với remote)
**Mục tiêu Phase 5:** `terraform destroy` → `terraform apply` → app chạy lại bình thường

---

## Trạng thái hiện tại

| Step | Nội dung | Status |
|------|----------|--------|
| 1 | S3 backend + DynamoDB lock | ✅ Done |
| 2 | Module structure + provider.tf | ✅ Done |
| 3 | Module: vpc | ✅ Done |
| 4 | Module: ecr + iam | ✅ Done |
| 5 | Module: rds | ✅ Done |
| 6 | Module: alb | ✅ Done |
| 7 | Module: ecs | ✅ Done |
| 8 | terraform apply (brownfield import) | ✅ Done |
| **9** | **Verify: destroy → apply → app running** | **⬜ TODO** |

---

## Việc cần làm tiếp theo (Step 9)

### Bước 1: Recreate SSL cert (nếu /tmp bị xóa)

```bash
# Kiểm tra còn không
ls /tmp/combined-ca.pem && echo "OK" || echo "MISSING — cần recreate"

# Nếu missing, chạy lệnh này để recreate:
echo "" | openssl s_client -connect registry.terraform.io:443 -showcerts 2>/dev/null \
  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > /tmp/proxy-ca.pem
cat /etc/ssl/certs/ca-certificates.crt /tmp/proxy-ca.pem > /tmp/combined-ca.pem
```

### Bước 2: terraform destroy

```bash
SSL_CERT_FILE=/tmp/combined-ca.pem terraform -chdir=/home/nguyenbui/own-repos/claude-demo/infra destroy -var-file=environments/dev/terraform.tfvars
```

- Xóa toàn bộ 37 resources trong state
- Mất ~10–15 phút (RDS destroy chậm nhất)
- Nhập `yes` khi được hỏi

### Bước 3: terraform apply

```bash
SSL_CERT_FILE=/tmp/combined-ca.pem terraform -chdir=/home/nguyenbui/own-repos/claude-demo/infra apply -var-file=environments/dev/terraform.tfvars
```

- Tạo lại toàn bộ từ đầu (không cần import gì nữa)
- Mất ~10–15 phút (RDS provision chậm nhất)
- Nhập `yes` khi được hỏi

### Bước 4: Push image lên ECR mới

Sau destroy→apply, ECR repo bị xóa và tạo lại → không còn image. Cần push lại:

```bash
# Lấy ECR URL từ output
SSL_CERT_FILE=/tmp/combined-ca.pem terraform -chdir=/home/nguyenbui/own-repos/claude-demo/infra output ecr_url

# Login ECR
AWS_ECR_URL=028668155772.dkr.ecr.ap-southeast-1.amazonaws.com
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $AWS_ECR_URL

# Build và push từ repo gốc
cd /home/nguyenbui/own-repos/claude-demo
docker build -t claude-demo .
docker tag claude-demo:latest $AWS_ECR_URL/claude-demo:latest
docker push $AWS_ECR_URL/claude-demo:latest
```

### Bước 5: Verify app

```bash
# Lấy ALB DNS
ALB=$(SSL_CERT_FILE=/tmp/combined-ca.pem terraform -chdir=/home/nguyenbui/own-repos/claude-demo/infra output -raw alb_dns_name)
echo "ALB: $ALB"

# Chờ ~3 phút để ECS task healthy, rồi:
curl http://$ALB/health
# Expected: {"status": "ok", "version": "phase-04"}
```

---

## Terraform State hiện tại (37 resources)

State file: S3 `claude-demo-terraform-state-028668155772/dev/terraform.tfstate`

```
module.alb.*          (3 resources) — ALB, listener, target group
module.ecr.*          (2 resources) — ECR repo + lifecycle policy
module.ecs.*          (5 resources) — cluster, capacity_providers, log_group, task_def, service
module.iam.*          (6 resources) — roles, policies, OIDC provider
module.rds.*          (4 resources) — db instance, subnet_group, secret, secret_version
module.vpc.*          (17 resources) — VPC, subnets, route tables, SGs, IGW, NAT, EIP
```

---

## Cấu trúc files Terraform

```
infra/
├── backend.tf          — S3 backend (claude-demo-terraform-state-028668155772)
├── provider.tf         — AWS provider ~> 5.0
├── main.tf             — gọi 6 modules
├── variables.tf        — region, account_id, env, app_name, ...
├── outputs.tf          — alb_dns_name, db_endpoint, ecr_url, ...
├── .terraform.lock.hcl — committed (pin aws v5.100.0)
├── .gitignore          — exclude .terraform/, *.tfstate, environments/**/*.tfvars
├── modules/
│   ├── vpc/            — VPC, subnets, IGW, NAT, route tables, 3 SGs
│   ├── ecr/            — ECR repo + lifecycle policy (keep last 10 images)
│   ├── iam/            — ecsTaskExecutionRole, GitHub OIDC, github-actions role
│   ├── rds/            — RDS postgres 17, subnet group, Secrets Manager
│   ├── alb/            — ALB, target group (ip mode), listener port 80
│   └── ecs/            — cluster, task definition, service, CloudWatch logs
└── environments/
    └── dev/
        └── terraform.tfvars  — ⚠️ gitignored (có db_password)
```

---

## Context quan trọng

### Corporate proxy SSL workaround
Vingroup Web Gateway intercept HTTPS → cần `SSL_CERT_FILE` cho mọi lệnh terraform:
```bash
SSL_CERT_FILE=/tmp/combined-ca.pem terraform ...
```
File `/tmp/combined-ca.pem` không tồn tại sau reboot → xem Bước 1 để recreate.

### terraform.tfvars (gitignored)
File `infra/environments/dev/terraform.tfvars` chứa `db_password` → bị gitignore.
**Sau khi pull repo về nhà, cần tạo lại file này:**
```hcl
env               = "dev"
region            = "ap-southeast-1"
account_id        = "028668155772"
app_name          = "claude-demo"
github_org        = "nguyenbuitk"
db_instance_class = "db.t3.micro"
db_password       = "ovFL*~kjrGVZ|yWorMyLKqhfj~6t"
ecs_cpu           = 256
ecs_memory        = 512
desired_count     = 1
```

### Terraform binary
Cài tại `~/.local/bin/terraform` (v1.14.8). Nếu máy nhà chưa có:
```bash
wget https://releases.hashicorp.com/terraform/1.14.8/terraform_1.14.8_linux_amd64.zip
unzip terraform_1.14.8_linux_amd64.zip && mv terraform ~/.local/bin/
```

### terraform init (cần chạy lần đầu trên máy mới)
```bash
cd /home/nguyenbui/own-repos/claude-demo/infra
SSL_CERT_FILE=/tmp/combined-ca.pem terraform init
```

---

## Brownfield notes (đã xử lý)

Khi mới bắt đầu Phase 5, resources đã được tạo tay ở Phase 3-4 → phải `terraform import` trước khi apply. Đã xử lý xong. Sau Step 9 (destroy→apply), sẽ không cần import nữa vì mọi thứ được tạo từ Terraform.

**Các lifecycle ignore_changes trong `modules/rds/main.tf`:**
- `password` — RDS tạo tay với ManageMasterUserPassword=true
- `db_subnet_group_name` — RDS đang dùng subnet group tạo tay
- `vpc_security_group_ids` — SG của Terraform VPC mới vs VPC cũ

**Sau Step 9 (destroy→apply):** Các `ignore_changes` này có thể xóa bỏ (nếu muốn clean code), nhưng không bắt buộc.

---

## Verify Checklist (Step 9)

- [ ] `terraform destroy` thành công, không còn resource nào
- [ ] `terraform apply` tạo đủ: VPC, ECR, IAM, RDS, ALB, ECS
- [ ] Push Docker image lên ECR mới
- [ ] `curl http://<alb-dns>/health` → `{"status": "ok"}`
- [ ] Tạo task, kiểm tra data persist qua RDS
- [ ] State file có tại S3 `dev/terraform.tfstate`

---

## Sau khi hoàn thành Phase 5

1. Cập nhật ROADMAP.md và STATE.md: Phase 5 → Complete
2. Commit + push
3. Mở PR: `gsd/phase-05-terraform-iac` → `main`
4. Merge PR
5. Phase 6: Observability + Security (CloudWatch alarms, ECR scanning)
