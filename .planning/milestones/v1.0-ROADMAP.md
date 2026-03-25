# Roadmap: DevOps Learning Roadmap

---

## Milestone v1.0 — Docker + CI/CD Foundation ✓

**Goal:** Dockerize the Flask app and set up a fully working GitHub Actions CI/CD pipeline pushing to GHCR.
**Status:** Complete (2026-03-24)

### Phase 1: Dockerize ✓

**Goal:** Flask app runs in Docker with health check
**Depends on:** —
**Parallel:** No
**Requirements:** DOC-01, DOC-02, DOC-03
**Success Criteria:**
  1. `docker build -t claude-demo .` succeeds
  2. `docker run -p 5000:5000 claude-demo` serves the app
  3. `GET /health` returns `{"status": "ok"}` with HTTP 200
  4. `HEALTHCHECK` present in Dockerfile
**Plans:** 2 plans
Plans:
- [x] 01-01-PLAN.md — Add /health endpoint to Flask app with tests (DOC-02)
- [x] 01-02-PLAN.md — Multi-stage Dockerfile with HEALTHCHECK, .dockerignore and docker-compose cleanup (DOC-01, DOC-03)
**Files touched:** `Dockerfile`, `web.py`, `.dockerignore`, `docker-compose.yml`, `tests/test_web.py`

---

### Phase 2: CI/CD Pipeline ✓

**Goal:** Every merge to main builds and pushes Docker image to GHCR, gated on tests
**Depends on:** Phase 1
**Parallel:** No
**Requirements:** CI-01, CI-02, CI-03, CI-04
**Success Criteria:**
  1. PR triggers `test` job; `build-and-push` does NOT run on PRs
  2. Merge to main: `test` passes → `build-and-push` runs
  3. Failed test on main blocks Docker build
  4. `ghcr.io/nguyenbuitk/claude-demo:latest` and `:sha-<commit>` in GHCR after merge
  5. No manually created secrets — `GITHUB_TOKEN` only
**Plans:** 1 plan
Plans:
- [x] 02-01-PLAN.md — CI/CD workflow with test and build-and-push jobs (CI-01, CI-02, CI-03, CI-04)
**Files touched:** `.github/workflows/ci.yml`

---

## Milestone v2.0 — AWS Foundation (Docker-based, no K8s)

**Goal:** Flask app running on AWS with proper networking, container platform, and managed database. CI/CD pushes to ECR and deploys to ECS Fargate automatically.
**Note:** K8s deferred — using ECS Fargate (managed Docker on AWS) as stepping stone before EKS.

### Phase 3: AWS Networking + Registry

**Goal:** VPC sẵn sàng, IAM không dùng static keys, image được push lên ECR sau mỗi merge
**Depends on:** Phase 2
**Parallel:** No
**Requirements:** AWS-01, AWS-02, AWS-03, AWS-04, AWS-05
**Success Criteria:**
  1. VPC có public + private subnets trên 2 AZs, IGW, NAT gateway, route tables đúng
  2. GitHub Actions assume IAM role qua OIDC — không có AWS access key nào trong GitHub Secrets
  3. Merge to main → image được push lên `ECR_URI/claude-demo:latest` và `:sha-<commit>`
  4. Security group chỉ cho phép traffic cần thiết (least privilege)
  5. DB password được lưu trong Secrets Manager, không hardcode ở đâu
**Plans:** TBD
**Files touched:** `.github/workflows/ci.yml` (thêm ECR push job), `terraform/` (nếu dùng Terraform từ phase này)

---

### Phase 4: Deploy on AWS — ECS Fargate + RDS + ALB

**Goal:** App chạy trên ECS Fargate trong private subnet, có RDS PostgreSQL, public access qua ALB. CI/CD tự deploy khi merge to main.
**Depends on:** Phase 3
**Parallel:** No
**Requirements:** ECS-01, ECS-02, ECS-03, ECS-04, ECS-05
**Success Criteria:**
  1. `curl http://<alb-dns>/health` → `{"status": "ok"}` HTTP 200
  2. App đọc/ghi được vào RDS PostgreSQL (không còn dùng JSON file)
  3. Merge to main → ECS service tự rolling update lên image mới (zero downtime)
  4. ECS task fail health check → ECS tự restart, không cần can thiệp thủ công
  5. DB credentials lấy từ Secrets Manager qua IAM role — không có secret nào trong code
**Plans:** TBD
**Files touched:** `storage.py` (migrate JSON → PostgreSQL), `terraform/` hoặc AWS console setup, `.github/workflows/ci.yml` (thêm ECS deploy job)

---

## Milestone v3.0 — Infrastructure as Code

**Goal:** Toàn bộ hạ tầng v2.0 được mô tả bằng Terraform. Không còn setup thủ công. Multi-environment (dev/prod).

### Phase 5: Terraform

**Goal:** `terraform apply` từ đầu dựng lại được toàn bộ hạ tầng Phase 3+4. CI/CD chạy `terraform plan` trên PR và `apply` sau khi merge (với manual approval).
**Depends on:** Phase 4
**Parallel:** No
**Requirements:** TF-01, TF-02, TF-03, TF-04, TF-05
**Success Criteria:**
  1. `terraform destroy` → `terraform apply` → app chạy lại bình thường
  2. Remote state lưu trong S3, lock bằng DynamoDB — không conflict khi chạy song song
  3. Tách module: `vpc`, `ecr`, `ecs`, `rds`, `alb`, `iam` — mỗi module dùng độc lập được
  4. `dev` và `prod` environment có state riêng biệt
  5. PR tạo → GitHub Actions chạy `terraform plan`, output comment vào PR
**Plans:** TBD
**Files touched:** `terraform/` (toàn bộ), `.github/workflows/terraform.yml`

---

## Milestone v4.0 — Production Readiness + Observability

**Goal:** Không chỉ "chạy được" mà còn "vận hành được" — có monitoring, alerting, image scanning, và runbook.

### Phase 6: Observability + Security

**Goal:** CloudWatch logs + alarms, ECR image scanning, runbook đầy đủ. Mindset senior DevOps.
**Depends on:** Phase 5
**Parallel:** No
**Requirements:** OBS-01, OBS-02, OBS-03, OBS-04, OBS-05
**Success Criteria:**
  1. ECS container logs → CloudWatch Logs, có thể search bằng CloudWatch Insights
  2. Alarm kích hoạt khi: CPU >80%, memory >80%, unhealthy target count >0 → email/Slack
  3. ECR scan CVE khi push image — CI fail nếu có lỗ hổng CRITICAL
  4. `terraform apply` để xoá rồi tạo lại alarm — không setup tay
  5. Runbook có hướng dẫn xử lý ít nhất 3 sự cố: service down, DB connection fail, high CPU
**Plans:** TBD
**Files touched:** `terraform/` (CloudWatch, SNS), `docs/runbook.md`

---

## Progress Summary

| Phase | Milestone | Goal | Status |
|-------|-----------|------|--------|
| 1 | v1.0 | Dockerize Flask app | ✓ Complete |
| 2 | v1.0 | GitHub Actions CI/CD → GHCR | ✓ Complete |
| 3 | v2.0 | AWS networking, IAM OIDC, ECR | ○ Planned |
| 4 | v2.0 | ECS Fargate + RDS + ALB, auto-deploy | ○ Planned |
| 5 | v3.0 | Terraform IaC, remote state, multi-env | ○ Planned |
| 6 | v4.0 | CloudWatch, alarms, scanning, runbook | ○ Planned |
