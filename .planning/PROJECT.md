# DevOps Learning Roadmap

Personal DevOps learning project practiced on the `claude-demo` Flask app.
Target: AWS hands-on (ECS Fargate, RDS, ALB, ECR, Terraform) — probation evaluation context.

---

## Stack

| Layer | v1.0 (done) | v2.0 (current) | v3.0 (next) |
|-------|-------------|----------------|-------------|
| App | Python 3.12 / Flask | same | same |
| Container | Docker multi-stage | same | same |
| Registry | GHCR | GHCR + ECR | ECR only |
| CI/CD | GitHub Actions | + ECR push via OIDC | + terraform plan/apply |
| Deploy | — | ECS Fargate | Terraform |
| DB | JSON file | RDS PostgreSQL | same |
| Infra | — | AWS Console | Terraform |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| ECS Fargate over K8s | ECS covers deploy patterns for probation; EKS deferred |
| OIDC over static AWS keys | No secrets in GitHub, industry best practice |
| ECR alongside GHCR | ECR needed for ECS to pull images (same AWS network) |
| Reuse VMo VPC/subnets | Already has correct public/private structure across 2 AZs |
| Secrets Manager for DB creds | No hardcoded secrets, ECS task reads via IAM role |

---

## Real-world Target

Production stack: EKS, RDS Postgres, RabbitMQ, Redis, MongoDB, Nginx/ALB.
This project builds familiarity with AWS services before applying to that stack.
