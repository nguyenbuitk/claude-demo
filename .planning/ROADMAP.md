# Roadmap: DevOps Learning Roadmap v1.0

**Milestone:** v1.0 — Docker + CI/CD Foundation
**Goal:** Dockerize the Flask app and set up a fully working GitHub Actions CI/CD pipeline pushing to GHCR.

---

## Phase 1: Dockerize

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
- [ ] 01-01-PLAN.md — Add /health endpoint to Flask app with tests (DOC-02)
- [ ] 01-02-PLAN.md — Multi-stage Dockerfile with HEALTHCHECK, .dockerignore and docker-compose cleanup (DOC-01, DOC-03)
**Files touched:** `Dockerfile`, `web.py`, `.dockerignore`, `docker-compose.yml`, `tests/test_web.py`

---

## Phase 2: CI/CD Pipeline

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
**Plans:** TBD
**Files touched:** `.github/workflows/ci.yml`

---

## Future Milestones

| Milestone | Phases | Focus |
|-----------|--------|-------|
| v2.0 | Phase 3 | K8s local (Helm, HPA, probes) |
| v3.0 | Phase 4 | AWS foundation (VPC, EKS, ECR) |
| v4.0 | Phase 5 | Terraform + GitOps (ArgoCD) |
| v5.0 | Phase 6 | Observability + Production readiness |
