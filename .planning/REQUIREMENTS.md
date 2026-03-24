# Requirements: DevOps Learning Roadmap

**Defined:** 2026-03-24
**Core Value:** Every concept learned must be practiced hands-on and deployable to production-grade environments.

## v1 Requirements (Phase 1-2)

### Docker

- [ ] **DOC-01**: Dockerfile at repo root — multi-stage build, non-root user
- [ ] **DOC-02**: `/health` endpoint returns 200 JSON `{"status": "ok"}`
- [ ] **DOC-03**: `HEALTHCHECK` instruction in Dockerfile

### CI/CD (GitHub Actions)

- [ ] **CI-01**: `test` job runs on every PR and push to main
- [ ] **CI-02**: `build-and-push` job runs only on push to main, after `test` passes
- [ ] **CI-03**: Image pushed to `ghcr.io/nguyenbuitk/claude-demo:latest` and `:sha-<commit>`
- [ ] **CI-04**: Auth uses `GITHUB_TOKEN` only — no manually created secrets

## v2 Requirements (Phase 3-6)

### K8s (Phase 3)
- K8s manifests (Deployment, Service, Ingress, ConfigMap, Secret)
- HPA, liveness/readiness probes, resource limits
- Helm chart packaging

### AWS (Phase 4)
- VPC, EKS cluster, worker nodes, ALB ingress
- ECR as image registry, IAM roles with least privilege

### IaC + GitOps (Phase 5)
- Terraform modules (VPC, EKS, ECR, IAM)
- S3 backend + DynamoDB lock
- ArgoCD or Flux for GitOps

### Observability (Phase 6)
- Prometheus + Grafana + Loki/ELK
- Alerting for CPU, memory, pod restarts, service down
- Runbook, rollback strategy

## Out of Scope (v1.0)

| Feature | Reason |
|---------|--------|
| GitLab CI | Repo is on GitHub — GitHub Actions simpler for v1 |
| K8s local (minikube/kind) | Phase 3 |
| Multi-environment (dev/staging/prod) | Phase 2+ of phases.txt |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOC-01, DOC-02, DOC-03 | Phase 1 | Pending |
| CI-01, CI-02, CI-03, CI-04 | Phase 2 | Pending |
