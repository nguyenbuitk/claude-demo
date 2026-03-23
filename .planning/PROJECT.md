# Claude Demo — CI/CD Pipeline + Feature Expansion

## Current Milestone: v1.0 Full-Stack Feature Expansion

**Goal:** Hoàn thiện CI/CD pipeline và thêm 2 tính năng UX mới cho task manager, chạy song song bởi 3 luồng độc lập.

**Target features:**
- [DevOps] Build và push Docker image lên `ghcr.io/nguyenbuitk/claude-demo` khi merge vào main
- [Dev 1] Highlight đỏ task quá hạn, highlight vàng task sắp hết hạn (≤3 ngày)
- [Dev 2] Lịch sử task hoàn thành — danh sách, ngày hoàn thành, tách biệt active tasks

## What This Is

A Flask-based task manager app (Python 3.12, Gunicorn, Docker) with automated CI/CD and enhanced task visibility. The project adds a full CI/CD pipeline (test + build/push Docker), deadline-based task highlighting, and a completion history view.

## Core Value

Every PR shows test results so regressions are caught before they reach main.

## Requirements

### Validated

- ✓ Flask web app runs in Docker via docker-compose — existing
- ✓ Tests exist (`tests/`) and can be run locally via `pytest` — existing
- ✓ GitHub Actions workflows exist in `.github/workflows/` — existing

### Active

- [ ] A GitHub Actions workflow runs `pytest` on every pull request
- [ ] Test results are visible in the PR checks UI (pass/fail/output)
- [ ] Tests do NOT block merging — visibility only for now
- [ ] Workflow installs dependencies from `requirements.txt` correctly
- [ ] Workflow runs on Python 3.12 to match the production environment

### Out of Scope

- Deployment automation (auto-deploy after push) — deferred; push to registry is sufficient for now
- Blocking PR merges on failure — explicit choice; observability before enforcement
- Test coverage reporting — nice-to-have, deferred to a future phase
- Task reopen/undo completion — one-way completion is current design
- Search/filter by title or description — separate future feature

## Context

- **Existing CI:** Four GitHub Actions workflows exist but none execute `pytest`. The test suite is completely untested in CI.
- **Known gap documented:** `.planning/codebase/CONCERNS.md` explicitly flags "No CI job runs pytest" as high severity.
- **Test suite state:** `tests/` directory exists with at least `test_tasks.py`. No coverage for `storage.py` or Flask routes yet — but that's a separate concern.
- **Deps:** `requirements.txt` pins 4 direct dependencies; `pytest` is not pinned there (invoked via `pytest` command).
- **Concurrency concern:** Gunicorn runs 4 workers writing to `tasks.json` with no locking — known issue, out of scope here.

## Constraints

- **Tech stack**: GitHub Actions only — no external CI services; existing workflows use `ubuntu-latest`
- **Python version**: Must use Python 3.12 to match the Dockerfile and production runtime
- **Scope**: Test visibility only — do not add merge-blocking branch protection rules

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Visibility-only (no PR gating) | New DevOps setup — observe baseline before enforcing | — Pending |
| Separate workflow file for tests | Keep test CI distinct from Claude Code review workflows | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-23 after milestone v1.0 started*
