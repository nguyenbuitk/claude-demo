# DevOps Learning Roadmap

## What This Is

Personal DevOps learning roadmap practiced on the `claude-demo` Flask app and applied to real work at VinMotion. v1.0 shipped Docker + GitHub Actions CI/CD. Now targeting AWS (ECS Fargate, RDS, ALB, ECR, Terraform) without K8s — ECS Fargate as a stepping stone before EKS.

## Core Value

Every concept learned must be practiced hands-on and deployable to production-grade environments — no theory-only.

## Requirements

### Validated

- ✓ Flask app runs locally — existing
- ✓ pytest suite — existing (8 tests after v1.0)
- ✓ `GET /health` endpoint returns `{"status": "ok"}` HTTP 200 — v1.0 Phase 1
- ✓ Multi-stage Dockerfile with HEALTHCHECK — v1.0 Phase 1
- ✓ GitHub Actions: `test` job on every PR and push to main — v1.0 Phase 2
- ✓ GitHub Actions: `build-and-push` to GHCR, gated on tests, main only — v1.0 Phase 2
- ✓ Image tagged `:latest` + `:sha-<commit>` — v1.0 Phase 2
- ✓ `GITHUB_TOKEN` only for auth (no manually created secrets) — v1.0 Phase 2

### Active (v2.0 targets)

- [ ] VPC with public/private subnets, IGW, NAT, security groups (AWS-01)
- [ ] GitHub Actions assumes IAM role via OIDC — no static access keys (AWS-02)
- [ ] Image pushed to ECR on merge to main (AWS-03)
- [ ] App deployed to ECS Fargate with RDS PostgreSQL backend (ECS-01, ECS-02)
- [ ] ALB in front of ECS, health check on `/health` (ECS-03)
- [ ] CI/CD auto-deploys to ECS on merge to main — zero downtime (ECS-04, ECS-05)

### Out of Scope

- K8s local (minikube/kind) — deferred, ECS Fargate covers deploy patterns first
- EKS — after v2.0 ECS experience
- GitOps (ArgoCD/Flux) — needs EKS first
- GitLab CI — repo on GitHub, Actions sufficient
- Multi-region — out of probation scope

## Context

- Repo: `claude-demo` (Python 3.12 / Flask, ~1,440 LOC Python + 1,615 HTML)
- Registry (v1.0): GHCR `ghcr.io/nguyenbuitk/claude-demo`
- Registry (v2.0): ECR `<account>.dkr.ecr.<region>.amazonaws.com/claude-demo` (parallel push)
- Real-world target: VinMotion stack (EKS, RDS Postgres, RabbitMQ, Redis, MongoDB, Nginx/ALB)
- Probation context: AWS hands-on practice is the primary evaluation criterion

## Constraints

- **Stack v1.0**: Python 3.12, Flask, GitHub Actions, Docker, GHCR
- **Stack v2.0**: Add AWS (ECS Fargate, RDS, ALB, ECR, Secrets Manager, IAM OIDC)
- **Stack v3.0**: Add Terraform (modules, remote state, multi-env)
- **No K8s until v2.0 is solid**: ECS Fargate first, EKS later

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| GitHub Actions over GitLab | Repo already on GitHub | ✓ Good — CI/CD working in Phase 2 |
| `claude-demo` as practice app | Existing Flask app, minimal setup overhead | ✓ Good — fast iteration |
| Multi-stage Dockerfile | Smaller image, non-root user, builder separation | ✓ Good — clean image |
| `GITHUB_TOKEN` only for GHCR | No manual secret management | ✓ Good — zero friction |
| ECS Fargate over K8s for v2.0 | K8s learning curve deferred; ECS covers deploy patterns for probation | Pending — v2.0 |
| Docker-first (no K8s in v2.0) | Probation timeline, AWS service familiarity is primary goal | Pending — v2.0 |

## Current State

**v1.0 shipped (2026-03-25).** Phase 1-2 complete:
- Flask app Dockerized with HEALTHCHECK and health endpoint
- GitHub Actions CI/CD: pytest gate → GHCR push on every merge to main
- PR #2 open: `gsd/phase-02-ci-cd-pipeline` → `main`

**Pending human smoke test** (requires live GitHub CI run):
1. PR suppresses `build-and-push`
2. Merge to main → `ghcr.io/nguyenbuitk/claude-demo:latest` appears in GHCR
3. Failing test on main → `build-and-push` skipped

**Next:** v2.0 AWS Foundation — `/gsd:discuss-phase 3` when AWS account ready.

---
*Last updated: 2026-03-25 after v1.0 milestone*
