# Roadmap: DevOps Learning Roadmap

## Milestones

- v1.0 Docker + CI/CD Foundation — Phases 1-2 (shipped 2026-03-25)
- v2.0 AWS Foundation — Phases 3-4 (shipped 2026-03-26)
- v3.0 Infrastructure as Code — Phase 5 (planned)
- v4.0 Production Readiness — Phase 6 (planned)

---

## Progress

| Phase | Description | Status | Completed |
|-------|-------------|--------|-----------|
| 1 | Dockerize (health endpoint, multi-stage Dockerfile) | Complete | 2026-03-24 |
| 2 | CI/CD Pipeline (GitHub Actions → GHCR) | Complete | 2026-03-24 |
| 3 | AWS Networking + Registry (VPC, ECR, OIDC, IAM, ECS cluster) | Complete | 2026-03-25 |
| 4 | ECS Fargate + RDS + ALB | Complete | 2026-03-26 |
| 5 | Terraform IaC | Planned | — |
| 6 | Observability + Security | Planned | — |

---

## Phase 4: ECS Fargate + RDS + ALB

**Goal:** App chạy trên ECS Fargate, RDS PostgreSQL, public access qua ALB, CI/CD tự deploy.

**Success criteria:**
1. `curl http://<alb-dns>/health` → `{"status": "ok"}` HTTP 200
2. App đọc/ghi được vào RDS PostgreSQL
3. Merge to main → ECS service rolling update (zero downtime)
4. ECS task fail health check → tự restart
5. DB credentials từ Secrets Manager qua IAM role

**Resources cần tạo:**
- ECS Task Definition + Service (Fargate)
- RDS PostgreSQL (private subnet, vmo-db-sg)
- ALB + Target Group + Listener (public subnet, vmo-alb-sg)
- Update ci.yml: thêm job deploy ECS sau khi push ECR

---

## Phase 5: Terraform IaC

**Goal:** `terraform apply` từ đầu dựng lại toàn bộ hạ tầng Phase 3+4.

**Success criteria:**
1. `terraform destroy` → `terraform apply` → app chạy lại bình thường
2. Remote state: S3 backend + DynamoDB lock
3. Modules: `vpc`, `ecr`, `ecs`, `rds`, `alb`, `iam`
4. `dev` và `prod` environment riêng biệt

---

## Phase 6: Observability + Security

**Goal:** CloudWatch logs + alarms, ECR image scanning, runbook.

**Success criteria:**
1. ECS logs → CloudWatch Logs, queryable via Insights
2. Alarms: CPU >80%, memory >80%, unhealthy target → email
3. ECR scan CVE khi push — CI fail nếu CRITICAL
4. Runbook: xử lý service down, DB fail, high CPU
