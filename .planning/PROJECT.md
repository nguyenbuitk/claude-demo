# Claude Demo — CI/CD Pipeline

## What This Is

A Flask-based task manager app (Python 3.12, Gunicorn, Docker) that currently has no automated test execution. This project adds a CI/CD pipeline so that `pytest` runs on every pull request, giving the team visibility into test results before merging.

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

- Docker image build/push — not part of this phase; pipeline is test-only for now
- Deployment automation — deferred; focus is test visibility first
- Blocking PR merges on failure — explicit choice; observability before enforcement
- Test coverage reporting — nice-to-have, deferred to a future phase

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
*Last updated: 2026-03-23 after initialization*
