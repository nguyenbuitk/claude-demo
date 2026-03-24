# DevOps Learning Roadmap

## What This Is

Personal DevOps learning roadmap practiced on the `claude-demo` Flask app and applied to real work at VinMotion. Covers Docker → CI/CD → K8s → AWS → IaC/GitOps → Observability.

## Core Value

Every concept learned must be practiced hands-on and deployable to production-grade environments.

## Requirements

### Validated

- ✓ Flask app runs locally — existing
- ✓ pytest suite (4 tests) — existing
- ✓ GitHub Actions test workflow on PRs — Phase 1

### Active

- [x] Dockerize the Flask app (Dockerfile + health check) — Validated in Phase 1: Dockerize
- [x] CI/CD: build + push to GHCR on merge to main, gated on tests — Validated in Phase 2: CI/CD Pipeline
- [ ] Verify full CI pipeline works end-to-end on GitHub (human smoke test pending)

### Out of Scope (v1.0)

- K8s local cluster — Phase 3
- AWS/EKS — Phase 4
- Terraform + GitOps — Phase 5
- Observability (Prometheus, Grafana) — Phase 6

## Context

- Repo: `claude-demo` (Python/Flask, JSON storage, no DB)
- CI: GitHub Actions (not GitLab — easier for this repo)
- GHCR registry: `ghcr.io/nguyenbuitk/claude-demo`
- Real-world target: VinMotion (EKS, RDS Postgres, RabbitMQ, Redis, MongoDB)

## Constraints

- **Stack**: Python 3.12, Flask, GitHub Actions only for v1.0
- **Scope**: v1.0 = Phase 1-2 (Docker + CI/CD) only

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| GitHub Actions over GitLab | Repo already on GitHub | Confirmed — Phase 2 complete |
| claude-demo as practice app | Existing app, minimal setup | Confirmed — Phase 1+2 complete |

## Current State

Phase 2 complete — `ci.yml` with `test` + `build-and-push` jobs deployed. v1.0 milestone (Phase 1-2) fully implemented. Pending: human smoke-test (PR suppression, GHCR image visibility, test-failure gate).

---
*Last updated: 2026-03-24*
