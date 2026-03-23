# Project Research Summary

**Project:** Claude Demo — CI/CD Pipeline (pytest on PR)
**Domain:** GitHub Actions CI workflow for Python/Flask
**Researched:** 2026-03-23
**Confidence:** HIGH

## Executive Summary

This project adds a single GitHub Actions workflow file (`.github/workflows/test.yml`) that runs `pytest` on every pull request against the existing Flask/Python 3.12 app. The approach is deliberately minimal: one job, no matrix, no branch protection, no test reporters — just test execution with results visible in the PR checks UI. All four parallel research threads converge on an identical ~20-line YAML file as the complete deliverable.

The recommended implementation installs dependencies via `pip install -r requirements.txt pytest` (pytest is confirmed absent from `requirements.txt`), uses `actions/setup-python@v5` with `python-version: "3.12"` and `cache: "pip"`, and runs `pytest -v`. This matches the production runtime, caches dependencies for speed, and produces readable output in the GitHub Actions log without any marketplace dependencies or added complexity.

The key risks are all pre-empted by the recommended approach: forgetting to install pytest alongside `requirements.txt` would cause immediate failure, and using the wrong Python version would silently hide compatibility issues. Both are avoided by the canonical YAML below. One latent risk — `storage.py` file I/O has no test isolation — is dormant for this milestone but must be addressed before any storage tests are added in a future phase.

---

## Key Findings

### Recommended Stack

All four research files agree on the same action versions and runner. The existing repo workflows confirm `actions/checkout@v4` is already in use; `actions/setup-python@v5` is the current stable major as of the knowledge cutoff (August 2025) and should be verified before implementation.

**Core technologies:**
- `actions/checkout@v4` — repo checkout — confirmed in existing `.github/workflows/claude-code-review.yml`
- `actions/setup-python@v5` — Python 3.12 install + pip cache — MEDIUM confidence on exact version; verify latest major tag
- `ubuntu-latest` — runner OS — consistent with all four existing workflows in this repo
- `pip install -r requirements.txt pytest` — dependency install — HIGH confidence; derived from direct inspection of `requirements.txt`
- `pytest -v` — test runner with verbose output — HIGH confidence; no `pytest.ini` needed, auto-discovers `tests/`

### Expected Features

**Must have (table stakes):**
- `on: pull_request` trigger — required for results to appear in the PR checks UI
- `python-version: "3.12"` — must match production Dockerfile runtime
- Install from `requirements.txt` — Flask/Werkzeug/Jinja2/Gunicorn are required for test imports
- Install `pytest` explicitly — it is not in `requirements.txt`
- `runs-on: ubuntu-latest` — consistent with all existing repo workflows

**Should have (zero added complexity):**
- `cache: "pip"` in `setup-python` — saves ~20-40s per run, one extra YAML line
- `pytest -v` verbose flag — makes individual test names visible in the GitHub log
- Concurrency group — cancels stale runs on rapid pushes to the same PR

**Defer (v2+):**
- Coverage reporting — explicitly out of scope in PROJECT.md
- Branch protection / required checks — visibility-only is the stated goal for v1
- Matrix builds across Python versions — app targets exactly 3.12
- JUnit XML + test reporter action — adds marketplace dependency; defer until test suite grows
- `workflow_dispatch` trigger — not needed for pure CI

### Architecture Approach

Create a new file at `.github/workflows/test.yml`. Do not extend any existing workflow — the four existing workflows serve unrelated purposes (Claude code review, hello world demo, main demo). Separation of concerns: test CI is independent of review automation and demo workflows.

**Workflow structure:**
1. Trigger — `pull_request` (opened, synchronize, reopened) + optionally `push` to `main`
2. Single job `test` on `ubuntu-latest` with `permissions: contents: read`
3. Checkout step using `actions/checkout@v4`
4. Python setup step using `actions/setup-python@v5` with version pin and pip cache
5. Install step combining `requirements.txt` and `pytest` in one command
6. Test step running `pytest -v`

The ARCHITECTURE.md researcher recommends also triggering on `push` to `main` to catch direct merges; the STACK.md researcher recommends omitting it for now (PROJECT.md scopes to PR-only). This is the one open decision — see below.

### Critical Pitfalls

1. **pytest missing from requirements.txt** — use `pip install -r requirements.txt pytest` in a single command; do not run `pip install pytest` alone or the Flask imports in tests will fail
2. **Python version not pinned** — use `python-version: "3.12"` explicitly; `ubuntu-latest` does not default to 3.12 and `"3.x"` would follow minor upgrades silently
3. **Wrong trigger** — `on: push` alone does not populate the PR checks UI; `on: pull_request` is required for results to appear where reviewers see them
4. **No test isolation for storage.py** — `storage.py` hardcodes `tasks.json` at the repo root; dormant now but will cause flaky tests the moment any storage test is added; fix with `monkeypatch`/`tmp_path` when that time comes
5. **sys.path boilerplate spreading** — `test_tasks.py` manually inserts repo root into `sys.path`; adding a root-level `conftest.py` now prevents every future test file from needing the same boilerplate

---

## Recommended Workflow YAML

This is the complete deliverable for Phase 1. All research threads converge on this structure:

```yaml
name: Tests

on:
  pull_request:
    types: [opened, synchronize, reopened]

concurrency:
  group: tests-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python 3.12
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: Install dependencies
        run: |
          pip install --upgrade pip
          pip install -r requirements.txt pytest

      - name: Run tests
        run: pytest -v
```

---

## Implications for Roadmap

This project is a single-phase deliverable. All five active requirements from PROJECT.md are satisfied by the workflow above. There is no meaningful second phase until the team decides to expand scope.

### Phase 1: pytest CI Workflow
**Rationale:** All work is additive — one new file, no changes to existing code or workflows.
**Delivers:** Automated test execution on every PR, results visible in the PR checks UI.
**Addresses:** All five active requirements in PROJECT.md.
**Avoids:** Pitfalls 1, 2, 3 (all blockers) by construction of the YAML.
**Optional additions:** `conftest.py` at repo root (pitfall 5 prevention); concurrency group (stale run cancellation).

### Phase 2 (Future): Expand Test Coverage
**Rationale:** Deferred; depends on team deciding to write tests for `storage.py` or Flask routes.
**Prerequisite:** Pitfall 4 (storage.py isolation) must be addressed before any storage tests land.
**May add:** Coverage reporting, branch protection rules, JUnit XML output.

### Research Flags

Standard patterns, no further research needed:
- **Phase 1:** GitHub Actions + pytest CI is one of the most well-documented patterns in the ecosystem. The YAML is fully specified by research. Implement directly.

Needs research before starting:
- **Phase 2 (if pursued):** Flask route testing patterns (`test_client`), `tmp_path` fixture usage for file-based storage, coverage tooling integration.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | `actions/checkout@v4` confirmed in repo; `actions/setup-python@v5` is training knowledge (cutoff Aug 2025) — verify latest major tag before implementing |
| Features | HIGH | Derived from direct codebase inspection (`requirements.txt`, `tests/test_tasks.py`, PROJECT.md) |
| Architecture | HIGH | Single new file; no integration complexity; consistent with existing workflow patterns in repo |
| Pitfalls | HIGH | Confirmed by direct inspection: pytest absent from `requirements.txt`, no `conftest.py`, `storage.py` hardcodes file path |

**Overall confidence:** HIGH

### Gaps to Address

- **`actions/setup-python` version:** Research used training knowledge (cutoff August 2025). Verify the latest stable major version tag on the [GitHub Marketplace](https://github.com/marketplace/actions/setup-python) before writing the workflow. `v5` is almost certainly still correct but takes 30 seconds to confirm.
- **`push` to `main` trigger:** ARCHITECTURE.md recommends adding it; STACK.md recommends omitting it. PROJECT.md scopes to PR-only. Decision: omit for v1, add in a future phase when the team wants main-branch visibility. This is logged in the YAML above as a comment opportunity.
- **conftest.py:** PITFALLS.md flags the missing `conftest.py` as a low-effort improvement. The team should decide whether to include it in Phase 1 alongside the workflow file. Recommended: yes, since it costs one file and prevents future boilerplate.

---

## Sources

### Primary (HIGH confidence)
- Codebase inspection: `requirements.txt`, `tests/test_tasks.py`, `.github/workflows/claude-code-review.yml`, `.planning/PROJECT.md`, `.planning/codebase/CONCERNS.md`

### Secondary (MEDIUM confidence)
- Training knowledge (cutoff August 2025): `actions/setup-python@v5` release, `cache: "pip"` behavior, pytest auto-discovery, GitHub Actions `pull_request` event semantics

---
*Research completed: 2026-03-23*
*Ready for roadmap: yes*
