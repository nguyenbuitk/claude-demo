# Pitfalls: pytest CI on GitHub Actions

**Domain:** GitHub Actions CI + pytest for Flask/Python 3.12
**Researched:** 2026-03-23
**Confidence:** HIGH

## Critical Pitfalls (blockers if missed)

### 1. pytest not in requirements.txt
**Risk:** `command not found` failure before any test runs
**Fix:** `pip install -r requirements.txt pytest` — append pytest explicitly to the install step
**This project:** Confirmed — `requirements.txt` contains only Flask, Werkzeug, Jinja2, Gunicorn

### 2. Python version not pinned
**Risk:** `ubuntu-latest` does not default to Python 3.12 — tests may run against the wrong version, hiding compatibility issues
**Fix:** `actions/setup-python@v5` with `python-version: "3.12"` explicitly
**This project:** No existing workflow sets up Python at all — this is a new requirement

### 3. `pull_request` trigger missing
**Risk:** A `push`-only trigger never appears in the PR review interface — tests run but results are invisible in the PR checks UI (the stated goal)
**Fix:** Use `on: pull_request` — this is what populates the Checks tab on a PR

## Latent Pitfalls (dormant now, will bite later)

### 4. storage.py file I/O — no test isolation
**Risk:** `storage.py` hardcodes `DATA_FILE` to the repo root (`tasks.json`). If tests are added for `storage.py`, concurrent or sequential test runs will read/write the real `tasks.json` in the CI workspace. Tests will corrupt each other's state and produce flaky results.
**Fix when adding storage tests:** Use `monkeypatch` or `tmp_path` fixture to redirect `DATA_FILE` per test
**Current state:** Dormant — existing tests in `test_tasks.py` don't touch `storage.py`

### 5. sys.path fragility — no conftest.py
**Risk:** `test_tasks.py` manually inserts the repo root into `sys.path`. Every new test file needs the same boilerplate, or imports will fail.
**Fix:** Add a `conftest.py` at the repo root to centralise `sys.path` — one file prevents the pattern from spreading
**Effort:** Minimal — can be added alongside the CI workflow

## Low-Risk Pitfalls

### 6. pytest version unpinned
**Risk:** Silent behavior changes between CI runs if pytest releases a breaking change
**Severity:** Low for small projects
**Fix if needed:** Add `pytest==<version>` to a `requirements-dev.txt` when test suite grows

### 7. Cache invalidation on dep changes
**Risk:** `setup-python@v5` `cache: "pip"` keys on `requirements.txt` hash — changes to `requirements.txt` invalidate the cache correctly. No action needed.
**Severity:** None — built-in behavior is correct

## Roadmap Implications

| Phase | Action |
|-------|--------|
| Phase 1 (workflow creation) | Fix pitfalls 1, 2, 3 — all are blockers |
| Phase 1 (optional) | Add `conftest.py` to prevent pitfall 5 from spreading |
| Future phase (storage tests) | Address pitfall 4 with `monkeypatch`/`tmp_path` before writing any storage test |

---
*Pitfalls analysis: 2026-03-23*
