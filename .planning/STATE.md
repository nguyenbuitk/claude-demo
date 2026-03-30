# Project State

**Updated:** 2026-03-30
**Milestone:** v4.0 Production Readiness

---

## Current Status

**Phase 6 — In Progress**
**Branch:** `gsd/phase-06-observability-security`

---

## Phase 5 — Complete (2026-03-30)

Terraform IaC viết lại từ đầu cho project-1.

| Module | Resources | Status |
|--------|-----------|--------|
| vpc | VPC 10.1.0.0/16, subnets, IGW, NAT, SGs | ✅ |
| ecr | ECR repo project-1 | ✅ |
| iam | ECS execution role + GitHub OIDC | ✅ |
| rds | PostgreSQL 17 + Secrets Manager | ✅ |
| alb | ALB + target group + listener | ✅ |
| ecs | Fargate cluster + task + service | ✅ |

- State: S3 `claude-demo-terraform-state-028668155772/project-1/terraform.tfstate`
- App: `curl http://project-1-dev-alb-856207708.ap-southeast-1.elb.amazonaws.com/health` → `{"status":"ok","version":"phase-04"}`
- CI/CD: push to main → build ECR → deploy ECS (project-1-dev-cluster/project-1-dev-svc)

---

## Phase 6 — Observability + Security

**Goal:** CloudWatch logs + alarms, ECR scan, runbook.

**Success criteria:**
1. ECS logs → CloudWatch Logs, queryable via Insights
2. Alarms: CPU >80%, memory >80%, unhealthy target → SNS email
3. ECR scan CVE khi push — CI fail nếu CRITICAL
4. Runbook: xử lý service down, DB fail, high CPU

---

## AWS Account

- Account: `028668155772`
- Region: `ap-southeast-1` (Singapore)
- GitHub repo: `nguyenbuitk/claude-demo`
- ALB: `project-1-dev-alb-856207708.ap-southeast-1.elb.amazonaws.com`
- ECR: `028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/project-1`
- ECS Cluster: `project-1-dev-cluster`
- ECS Service: `project-1-dev-svc`
