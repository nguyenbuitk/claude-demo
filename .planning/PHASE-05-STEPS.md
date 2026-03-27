# Phase 5 — Terraform IaC

**Goal:** `terraform destroy` → `terraform apply` → app chạy lại bình thường
**Branch:** `gsd/phase-05-terraform-iac`
**AWS Region:** ap-southeast-1 | Account: 028668155772
**Terraform:** v1.14.8 (đã cài tại `~/.local/bin/terraform`)

## Progress

| Step | Resource | Status |
|------|----------|--------|
| 1 | S3 backend + DynamoDB lock (Console) + backend.tf | ✅ Done (2026-03-27) |
| 2 | Module structure + provider.tf | ✅ Done (2026-03-27) |
| 3 | Module: vpc | ✅ Done (2026-03-27) |
| 4 | Module: ecr + iam | ✅ Done (2026-03-27) |
| 5 | Module: rds | ✅ Done (2026-03-27) |
| 6 | Module: alb | ✅ Done (2026-03-27) |
| 7 | Module: ecs | ✅ Done (2026-03-27) |
| 8 | Environment dev + terraform init/apply | ⬜ Todo |
| 9 | Verify: destroy → apply → app running | ⬜ Todo |

## Key Values (từ Phase 3-4, dùng để viết Terraform)

```
AWS Account     : 028668155772
Region          : ap-southeast-1

VPC             : vpc-0120771daf2f1aea3 (10.0.0.0/16)
Public subnets  : subnet-0cf9522c9c38535bd (vmo-public-1a)
                  subnet-0020b40a7df8faf3d (vmo-public-1b)
Private subnets : subnet-04325cd1624327a16 (vmo-private-1a)
                  subnet-060604d39d5de044e (vmo-private-1b)
Internet GW     : igw-028fff24dd81ecf41
NAT Gateway     : nat-0a949df919e2b23ac (vmo-public-1a)
EIP (NAT)       : eipalloc-07b05a4db6dd3f969

SG - ALB        : sg-0166254711a3b5ae5 (vmo-alb-sg)
SG - ECS        : sg-01374c41c25a9809f (vmo-eks-sg)
SG - RDS        : sg-0a6cc925b46fce8bf (vmo-db-sg)

ECR             : 028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo
OIDC Provider   : token.actions.githubusercontent.com
IAM Role        : github-actions-claude-demo
ECS Cluster     : claude-demo (Fargate)
ECS Service     : claude-demo-svc
Task Definition : claude-demo:5

RDS             : claude-demo-db.cdouj2djsuhw.ap-southeast-1.rds.amazonaws.com
                  db.t3.micro | PostgreSQL 17.6 | 20 GB gp2
ALB             : claude-demo-alb-2024146360.ap-southeast-1.elb.amazonaws.com
Secret          : claude-demo/db-password
```

---

## Step 1: S3 Backend + DynamoDB Lock ⬜

**Mục tiêu:** Tạo nơi lưu Terraform state trên S3 (có versioning) và DynamoDB để lock state khi apply.

**Console steps:**

### 1a. Tạo S3 bucket

1. **S3 → Buckets → Create bucket**
   - Bucket name: `claude-demo-terraform-state-028668155772`
   - AWS Region: `ap-southeast-1`
   - Object Ownership: ACLs disabled (default)
   - Block all public access: ✅ (default)
   - Bucket Versioning: **Enable** ✓
   - Default encryption: SSE-S3 (default)
   - → **Create bucket**

### 1b. Tạo DynamoDB table

2. **DynamoDB → Tables → Create table**
   - Table name: `claude-demo-terraform-locks`
   - Partition key: `LockID` — type **String**
   - Table settings: Default settings
   - → **Create table**

### 1c. Tạo backend.tf

3. Tạo file `infra/backend.tf`:
   ```hcl
   terraform {
     required_version = ">= 1.0"

     backend "s3" {
       bucket         = "claude-demo-terraform-state-028668155772"
       key            = "dev/terraform.tfstate"
       region         = "ap-southeast-1"
       dynamodb_table = "claude-demo-terraform-locks"
       encrypt        = true
     }
   }
   ```

---

## Step 2: Module Structure + provider.tf ⬜

**Tạo cấu trúc thư mục và provider:**

```
infra/
├── backend.tf
├── provider.tf
├── variables.tf
├── outputs.tf
├── main.tf                    ← gọi các modules
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecs/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── dev/
        └── terraform.tfvars
```

**`infra/provider.tf`:**
```hcl
provider "aws" {
  region = var.region
}
```

---

## Step 3: Module vpc ⬜

**Resources Terraform sẽ tạo:**
- `aws_vpc` (10.0.0.0/16)
- `aws_subnet` × 4 (2 public + 2 private, 2 AZ)
- `aws_internet_gateway`
- `aws_eip` (cho NAT)
- `aws_nat_gateway` (public-1a)
- `aws_route_table` × 2 (public + private)
- `aws_route_table_association` × 4
- `aws_security_group` × 3 (alb-sg, ecs-sg, rds-sg)

**Security Group rules:**
- `alb-sg`: inbound 80/443 từ 0.0.0.0/0
- `ecs-sg`: inbound 5000 từ alb-sg
- `rds-sg`: inbound 5432 từ ecs-sg

**Outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `alb_sg_id`, `ecs_sg_id`, `rds_sg_id`

---

## Step 4: Module ecr + iam ⬜

**ECR resources:**
- `aws_ecr_repository` (name=claude-demo, scan_on_push=true, force_delete=true)

**IAM resources:**
- `aws_iam_role` — `ecsTaskExecutionRole`
- `aws_iam_role_policy_attachment` — AmazonECSTaskExecutionRolePolicy
- `aws_iam_role_policy` — inline: `secretsmanager:GetSecretValue` cho RDS-managed secret
- `aws_iam_openid_connect_provider` — GitHub Actions OIDC
- `aws_iam_role` — `github-actions-claude-demo`
- `aws_iam_role_policy` — `claude-demo-ci-policy` (ECR push + ECS deploy + iam:PassRole)

**Outputs:** `ecr_url`, `task_execution_role_arn`, `github_actions_role_arn`

---

## Step 5: Module rds ⬜

**Resources Terraform sẽ tạo:**
- `aws_db_subnet_group` (dùng private subnets)
- `aws_db_instance`
  - engine: `postgres`, version: `17`
  - instance_class: `db.t3.micro`
  - storage: 20 GB gp2
  - db_name: `claude_demo`
  - username: `postgres`
  - password: từ variable (lưu vào Secrets Manager thủ công sau)
  - skip_final_snapshot: true (dev env)
- `aws_secretsmanager_secret` — `claude-demo/db-password`
- `aws_secretsmanager_secret_version` — key `password`

**Outputs:** `db_endpoint`, `db_secret_arn`

---

## Step 6: Module alb ⬜

**Resources Terraform sẽ tạo:**
- `aws_lb`
  - name: `claude-demo-alb`
  - internal: false (internet-facing)
  - load_balancer_type: `application`
  - subnets: public subnets
- `aws_lb_target_group`
  - port: 5000, protocol: HTTP
  - target_type: `ip` (Fargate dùng IP mode)
  - health_check: path=/health, interval=30s, threshold=3
- `aws_lb_listener`
  - port: 80 → forward to target group

**Outputs:** `alb_dns_name`, `target_group_arn`

---

## Step 7: Module ecs ⬜

**Resources Terraform sẽ tạo:**
- `aws_ecs_cluster` (name: claude-demo, Fargate capacity provider)
- `aws_cloudwatch_log_group` (`/ecs/claude-demo`, retention: 7 ngày)
- `aws_ecs_task_definition`
  - family: `claude-demo`
  - cpu: 256, memory: 512
  - network_mode: `awsvpc`
  - image: từ ECR (`:latest`)
  - secrets: DB_HOST, DB_USER, DB_PASS từ Secrets Manager
  - logConfiguration: awslogs → `/ecs/claude-demo`
  - healthCheck: python urllib `/health`
- `aws_ecs_service`
  - desired_count: 1
  - launch_type: FARGATE
  - subnets: private subnets
  - load_balancer: target_group_arn
  - deployment_minimum_healthy_percent: 100
  - deployment_maximum_percent: 200

**Outputs:** `cluster_name`, `service_name`

---

## Step 8: Environment dev + Apply ⬜

**`infra/environments/dev/terraform.tfvars`:**
```hcl
env               = "dev"
region            = "ap-southeast-1"
account_id        = "028668155772"
app_name          = "claude-demo"
db_instance_class = "db.t3.micro"
ecs_cpu           = 256
ecs_memory        = 512
desired_count     = 1
github_org        = "nguyenbuitk"
```

**Chạy:**
```bash
cd infra
terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Xác nhận trên Console sau khi apply:**
- **S3**: bucket `claude-demo-terraform-state-028668155772` có file `dev/terraform.tfstate`
- **ECS**: Cluster `claude-demo` → Service running, task healthy
- **RDS**: Instance `available`
- **ALB**: State `active`

---

## Step 9: Verify ⬜

```bash
# 1. Destroy toàn bộ infra
terraform destroy -var-file=environments/dev/terraform.tfvars

# 2. Apply lại từ đầu
terraform apply -var-file=environments/dev/terraform.tfvars

# 3. Lấy ALB DNS từ Terraform output
terraform output alb_dns_name

# 4. Kiểm tra health (chờ ~3 phút ECS task healthy)
curl http://<alb_dns>/health
# Expected: {"status": "ok", "version": "phase-04"}

# 5. Tạo task → kiểm tra data persist qua RDS
curl -X POST http://<alb_dns>/add -d "title=terraform-test&priority=high"
curl http://<alb_dns>/
```

---

## Verify Checklist

- [ ] S3 bucket `claude-demo-terraform-state-028668155772` tồn tại, versioning enabled
- [ ] DynamoDB table `claude-demo-terraform-locks` tồn tại
- [ ] `terraform init` → backend S3 connected thành công
- [ ] `terraform plan` không có lỗi
- [ ] `terraform apply` tạo đủ: VPC, ECR, IAM, RDS, ALB, ECS cluster + service
- [ ] `curl http://<alb-dns>/health` → `{"status": "ok"}`
- [ ] `terraform destroy` → `terraform apply` → app vẫn chạy
- [ ] State file có tại S3 `dev/terraform.tfstate`
