# Project State

**Updated:** 2026-03-25
**Milestone:** v2.0 AWS Foundation

---

## Current Status

**Phase 3 — Complete**

AWS resources đã tạo (ap-southeast-1):

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

**Branch:** `gsd/phase-03-aws-networking-registry` — pending PR → main

---

## Next: Phase 4 — ECS Fargate + RDS + ALB

Thứ tự tạo:
1. RDS PostgreSQL (private subnet, db.t3.micro, vmo-db-sg)
2. ECS Task Definition (image từ ECR, env từ Secrets Manager)
3. ECS Service (Fargate, private subnet)
4. ALB + Target Group + Listener (public subnet, vmo-alb-sg)
5. Update ci.yml: thêm job `deploy-ecs` sau `build-and-push-ecr`
6. Update app: migrate storage.py từ JSON file sang PostgreSQL

---

## AWS Account

- Account: `028668155772`
- Region: `ap-southeast-1` (Singapore)
- IAM User: `nguyen-bui-iam`
- GitHub repo: `nguyenbuitk/claude-demo`
