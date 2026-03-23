# Feature Landscape: pytest CI Workflow

**Domain:** GitHub Actions CI pipeline for a Python/Flask project
**Researched:** 2026-03-23
**Confidence:** HIGH

## Context

This milestone adds a single GitHub Actions workflow that runs `pytest` on every pull request.
The explicit goal is **visibility, not enforcement** — test results appear in the PR checks UI
but a failing test does not block merge. The app is Python 3.12 / Flask with dependencies pinned
in `requirements.txt` (Flask, Werkzeug, Jinja2, Gunicorn). `pytest` is not currently pinned in
`requirements.txt`.

## Table Stakes

| Feature | Why Required | Implementation Note |
|---------|--------------|---------------------|
| Trigger on `pull_request` events | Core requirement — tests run on every PR | `on: pull_request` with types `[opened, synchronize, reopened]` |
| `actions/checkout@v4` | Required to access repo code | Already the standard in this repo's other workflows |
| `actions/setup-python@v5` with `python-version: "3.12"` | Must match production runtime | Pin to `"3.12"` explicitly — do not use `"3.x"` |
| Install deps from `requirements.txt` | App imports Flask, Werkzeug, etc. — tests fail to import without them | `pip install -r requirements.txt` |
| Install `pytest` explicitly | `pytest` is not in `requirements.txt` | `pip install pytest` |
| Run `pytest` and capture exit code | Actual test execution | `pytest tests/` |
| Result visible in PR checks UI | The stated value | Automatic when workflow is named and job completes |
| `runs-on: ubuntu-latest` | Consistent with all other workflows in this repo | No reason to deviate |

## Nice-to-Have (include in v1 — zero added complexity)

| Feature | Value | Recommendation |
|---------|-------|----------------|
| `cache: "pip"` in `setup-python` | Faster runs (~20-40s saved) | Add it — one extra line, built-in to the action |
| `pytest --tb=short -v` flags | Shorter tracebacks + verbose test names | Add it — cosmetic, zero risk |
| Concurrency group | Cancels stale runs on rapid pushes | Add it — 2 lines of YAML, standard pattern |

## Anti-Features (explicitly exclude)

| Anti-Feature | Why to Avoid |
|--------------|--------------|
| Branch protection / required checks | Out of scope — visibility only |
| Coverage reporting | Explicitly deferred in PROJECT.md |
| Matrix builds (multiple Python versions) | App targets exactly Python 3.12 |
| Docker-based test execution | Over-engineering v1; direct runner is sufficient |
| JUnit XML + test-reporter action | Marketplace dependency; defer to v2 |
| `workflow_dispatch` trigger | Not needed for pure CI |

## MVP Recommendation

6 features, under 30 lines of YAML:
1. `on: pull_request` (opened, synchronize, reopened)
2. `concurrency` group to cancel stale runs
3. `actions/checkout@v4`
4. `actions/setup-python@v5` with `python-version: "3.12"` and `cache: "pip"`
5. `pip install -r requirements.txt pytest`
6. `pytest tests/ -v --tb=short`

---
*Features analysis: 2026-03-23*
