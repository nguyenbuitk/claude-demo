---
phase: 1
slug: dockerize
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 9.0.2 |
| **Config file** | none — conftest.py at root provides sys.path only |
| **Quick run command** | `pytest -x` |
| **Full suite command** | `pytest` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `pytest -x`
- **After every plan wave:** Run `pytest && docker build -t claude-demo .`
- **Before `/gsd:verify-work`:** Full suite must be green + `docker build` + `docker run` + `curl /health` all pass
- **Max feedback latency:** ~30 seconds (build + test)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | DOC-02 | unit | `pytest tests/test_web.py::test_health_endpoint -x` | No — Wave 0 | pending |
| 1-02-01 | 02 | 1 | DOC-02 | unit | `pytest tests/test_web.py::test_health_endpoint -x` | Yes after W0 | pending |
| 1-02-02 | 02 | 1 | DOC-01 | smoke | `docker build -t claude-demo . && docker run --rm claude-demo whoami` | N/A | pending |
| 1-02-03 | 02 | 1 | DOC-03 | smoke | `docker inspect claude-demo --format='{{.Config.Healthcheck}}'` | N/A | pending |
| 1-02-04 | 02 | 1 | DOC-03 | integration | `docker run -d -p 5000:5000 --name cd-test claude-demo && sleep 15 && docker inspect --format='{{.State.Health.Status}}' cd-test` | N/A | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_web.py` — Flask test client test for `/health` endpoint (DOC-02)

*Existing infrastructure (pytest, conftest.py) covers all other requirements. Only the health endpoint test file is new.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Container reaches "healthy" status after start-period | DOC-03 | Requires live Docker daemon + 15s wait | `docker run -d -p 5000:5000 --name cd-test claude-demo && sleep 15 && docker inspect --format='{{.State.Health.Status}}' cd-test` — expect `healthy`; then `docker stop cd-test && docker rm cd-test` |
| Non-root user inside container | DOC-01 | Requires live Docker daemon | `docker run --rm claude-demo whoami` — expect `appuser` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (tests/test_web.py)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
