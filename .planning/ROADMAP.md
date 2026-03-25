# Roadmap: DevOps Learning Roadmap

## Milestones

- ✅ **v1.0 Docker + CI/CD Foundation** — Phases 1-2 (shipped 2026-03-25)
- 🚧 **v2.0 AWS Foundation** — Phases 3-4 (planned)
- 📋 **v3.0 Infrastructure as Code** — Phase 5 (planned)
- 📋 **v4.0 Production Readiness** — Phase 6 (planned)

---

## Phases

<details>
<summary>✅ v1.0 Docker + CI/CD Foundation (Phases 1-2) — SHIPPED 2026-03-25</summary>

- [x] Phase 1: Dockerize (2/2 plans) — completed 2026-03-24
  - `GET /health` endpoint + Flask test suite
  - Multi-stage Dockerfile with HEALTHCHECK, `.dockerignore`
- [x] Phase 2: CI/CD Pipeline (1/1 plan) — completed 2026-03-24
  - GitHub Actions: `test` (pytest) + `build-and-push` to GHCR
  - Gated: test must pass, `GITHUB_TOKEN` only

Archive: `.planning/milestones/v1.0-ROADMAP.md`

</details>

---

### 🚧 v2.0 AWS Foundation (Planned)

#### Phase 3: AWS Networking + Registry

**Goal:** VPC sẵn sàng, IAM không dùng static keys, image push lên ECR sau mỗi merge
**Depends on:** Phase 2
**Requirements:** AWS-01, AWS-02, AWS-03, AWS-04, AWS-05
**Success Criteria:**
  1. VPC có public + private subnets trên 2 AZs, IGW, NAT gateway, route tables đúng
  2. GitHub Actions assume IAM role qua OIDC — không có AWS access key trong GitHub Secrets
  3. Merge to main → image push lên `ECR_URI/claude-demo:latest` và `:sha-<commit>`
  4. Security groups: least privilege (ALB → ECS → RDS only)
  5. DB password trong Secrets Manager, không hardcode
**Plans:** TBD
**Files touched:** `.github/workflows/ci.yml`, `terraform/` (optional)

---

#### Phase 4: ECS Fargate + RDS + ALB

**Goal:** App chạy trên ECS Fargate, có RDS PostgreSQL, public access qua ALB, CI/CD tự deploy
**Depends on:** Phase 3
**Requirements:** ECS-01, ECS-02, ECS-03, ECS-04, ECS-05
**Success Criteria:**
  1. `curl http://<alb-dns>/health` → `{"status": "ok"}` HTTP 200
  2. App đọc/ghi được vào RDS PostgreSQL (không còn dùng JSON file)
  3. Merge to main → ECS service rolling update lên image mới (zero downtime)
  4. ECS task fail health check → ECS tự restart
  5. DB credentials từ Secrets Manager qua IAM role — không có secret trong code
**Plans:** TBD
**Files touched:** `storage.py`, `.github/workflows/ci.yml`, `terraform/` hoặc AWS console

---

### 📋 v3.0 Infrastructure as Code (Planned)

#### Phase 5: Terraform

**Goal:** `terraform apply` từ đầu dựng lại toàn bộ hạ tầng Phase 3+4. Multi-environment.
**Depends on:** Phase 4
**Requirements:** TF-01, TF-02, TF-03, TF-04, TF-05
**Success Criteria:**
  1. `terraform destroy` → `terraform apply` → app chạy lại bình thường
  2. Remote state: S3 backend + DynamoDB lock
  3. Modules: `vpc`, `ecr`, `ecs`, `rds`, `alb`, `iam`
  4. `dev` và `prod` environment có state riêng biệt
  5. PR → `terraform plan` comment; merge → `terraform apply` (manual approval)
**Plans:** TBD
**Files touched:** `terraform/`, `.github/workflows/terraform.yml`

---

### 📋 v4.0 Production Readiness (Planned)

#### Phase 6: Observability + Security

**Goal:** CloudWatch logs + alarms, ECR image scanning, runbook. Mindset senior DevOps.
**Depends on:** Phase 5
**Requirements:** OBS-01, OBS-02, OBS-03, OBS-04, OBS-05
**Success Criteria:**
  1. ECS logs → CloudWatch Logs, queryable via Insights
  2. Alarms: CPU >80%, memory >80%, unhealthy target → email/Slack
  3. ECR scan CVE khi push — CI fail nếu CRITICAL
  4. Alarm setup qua Terraform, không tay
  5. Runbook: xử lý ≥3 sự cố (service down, DB fail, high CPU)
**Plans:** TBD
**Files touched:** `terraform/`, `docs/runbook.md`

---

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1: Dockerize | v1.0 | 2/2 | ✅ Complete | 2026-03-24 |
| 2: CI/CD Pipeline | v1.0 | 1/1 | ✅ Complete | 2026-03-24 |
| 3: AWS Networking + Registry | v2.0 | TBD | ○ Planned | — |
| 4: ECS Fargate + RDS + ALB | v2.0 | TBD | ○ Planned | — |
| 5: Terraform | v3.0 | TBD | ○ Planned | — |
| 6: Observability + Security | v4.0 | TBD | ○ Planned | — |
