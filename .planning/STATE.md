# Project State

**Updated:** 2026-03-26
**Milestone:** v2.0 AWS Foundation

---

## Current Status

**Phase 4 — Complete (2026-03-26)**
**Branch:** `gsd/phase-04-ecs-fargate-rds-alb`

---

## Phase 3 — Complete (2026-03-25)

| Resource | Name/ID | Status |
|----------|---------|--------|
| VPC | vpc-0120771daf2f1aea3 (VMo, 10.0.0.0/16) | Ready |
| Subnets | 2 public + 2 private (1a + 1b) | Ready |
| Internet Gateway | igw-028fff24dd81ecf41 | Attached |
| NAT Gateway | nat-0f2053b8f748242d8 (public-1a) | Available |
| ECR | claude-demo (scanOnPush=true) | Ready |
| OIDC Provider | token.actions.githubusercontent.com | Ready |
| IAM Role | github-actions-claude-demo | Ready |
| ECS Cluster | claude-demo (Fargate) | Ready |
| Secrets Manager | claude-demo/db-password | Ready |
| CI/CD | ci.yml: test → GHCR + ECR (OIDC) | Deployed |

---

## Phase 4 — ECS Fargate + RDS + ALB

**Goal:** `curl http://<alb-dns>/health` → `{"status": "ok"}` HTTP 200

| Step | Resource | Detail | Status |
|------|----------|--------|--------|
| 1 | RDS PostgreSQL | private subnet, db.t3.micro, vmo-db-sg | ✅ Done |
| 2 | ECS Task Definition | image từ ECR, env từ Secrets Manager | ✅ Done |
| 3 | ALB + Target Group + Listener | public subnet, port 80 → 5000 | ✅ Done |
| 4 | ECS Service | Fargate, private subnet | ✅ Done |
| 5 | Update ci.yml | deploy-ecs job added | ✅ Done |
| 6 | Update storage.py | migrate JSON → PostgreSQL | ✅ Done |

**Pending:** Merge PR → CI deploy → verify `curl /health` returns `{"status":"ok","version":"phase-04"}`

---

## AWS Account

- Account: `028668155772`
- Region: `ap-southeast-1` (Singapore)
- IAM User: `nguyen-bui-iam`
- GitHub repo: `nguyenbuitk/claude-demo`
