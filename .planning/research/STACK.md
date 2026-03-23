# Technology Stack: GitHub Actions pytest CI

**Project:** Claude Demo — CI/CD Pipeline (pytest on PR)
**Researched:** 2026-03-23
**Scope:** GitHub Actions workflow stack for running pytest against a Python 3.12 Flask app

---

## Recommended Stack

### Core Actions

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `actions/checkout` | `v4` | Check out repository code | v4 is the current stable major; uses Node 20 runtime (v3 uses deprecated Node 16). Existing repo workflows already pin `@v4`. |
| `actions/setup-python` | `v5` | Install and configure Python | v5 is the current stable major as of mid-2024; adds support for `python-version-file`, better caching via `cache: 'pip'`, and uses Node 20 runtime. v4 still works but v5 is the forward-looking choice. |

**Confidence:** MEDIUM — based on training data (cutoff August 2025). `actions/checkout@v4` is confirmed in the repo's existing `claude-code-review.yml`. `actions/setup-python@v5` was released in 2024 and was current as of the knowledge cutoff; no web verification was possible in this environment.

### Runner OS

**Recommendation: `ubuntu-latest`**

Rationale:
- All four existing workflows in this repo use `ubuntu-latest` — consistency matters for developer familiarity.
- The production Dockerfile is Linux-based, so test results on Ubuntu are meaningful.
- Ubuntu runners are faster to provision and cheaper in GitHub Actions billing than Windows or macOS.
- No Windows-specific or macOS-specific code exists in this app; the test suite imports standard Python and the app's own modules.

**Confidence:** HIGH — this is a well-established pattern with no ambiguity.

### Python Version

**Recommendation: `python-version: "3.12"`**

Rationale:
- The Dockerfile and production runtime use Python 3.12 (confirmed in PROJECT.md).
- Matching CI to production prevents false passes: a test could pass on 3.11 but fail on 3.12 due to stdlib changes or deprecation warnings treated as errors.
- Pin the minor version (`"3.12"`) rather than just major (`"3"`) to avoid surprise upgrades when 3.13 becomes `latest`.

**Confidence:** HIGH — derived directly from the project's stated requirements.

### Dependency Installation

**Recommendation: `pip install -r requirements.txt pytest`**

Rationale:
- `requirements.txt` pins the four runtime deps (Flask, Werkzeug, Jinja2, Gunicorn). These must be installed so `from tasks import Task` and Flask imports in future route tests work.
- `pytest` is not in `requirements.txt` (confirmed by inspection — file contains only Flask/Werkzeug/Jinja2/Gunicorn). Install it explicitly alongside the requirements file rather than in a separate step, keeping the install step to a single `pip install` call.
- Do NOT use `pip install pytest` alone — that would omit Flask and break any test that imports the app.
- Do NOT use `pip install .[test]` — this project has no `pyproject.toml` or `setup.py`; there is no installable package.
- Add `pip install --upgrade pip` before the install step. pip upgrades are free and prevent hash-verification warnings on older bundled pip versions that can make CI logs noisy.

**Confidence:** HIGH — derived from direct inspection of `requirements.txt` and the test file's import structure.

### pip Caching

**Recommendation: Enable via `setup-python` built-in cache**

```yaml
- uses: actions/setup-python@v5
  with:
    python-version: "3.12"
    cache: "pip"
```

Rationale:
- `actions/setup-python@v5` supports `cache: 'pip'` natively. It caches the pip download cache keyed on `requirements.txt` hash, so re-runs only download packages when deps change.
- This typically saves 10-30 seconds per run for a small requirements file — low effort, consistent benefit.
- No separate `actions/cache` step needed; the built-in is simpler and less error-prone.

**Confidence:** HIGH — this is a well-documented feature of setup-python v4+.

### pytest Flags

**Recommendation: `pytest -v`**

Rationale:
- `-v` (verbose) prints each test name and its PASS/FAIL status in the GitHub Actions log. Without it, only a summary line appears, making it harder to identify which test failed when viewing inline in the PR checks UI.
- Do NOT add `--tb=short` or `--tb=long` explicitly — pytest's default traceback format is fine and keeps logs readable.
- Do NOT add `-x` (stop on first failure) — the goal is visibility of all failures, not fast-fail.
- Do NOT add `--cov` coverage flags yet — PROJECT.md explicitly defers coverage reporting to a future phase.
- No `pytest.ini` or `pyproject.toml` exists in the repo, so pytest will auto-discover tests in `tests/` by default. No `--rootdir` or `testpaths` config is required.

**Confidence:** HIGH — derived from the project's stated goal (visibility, not enforcement) and the test file structure.

### Trigger

**Recommendation: `on: pull_request`**

Rationale:
- PROJECT.md requirement: "A GitHub Actions workflow runs pytest on every pull request."
- Use the default event (no `types:` filter) to catch `opened`, `synchronize`, and `reopened` automatically.
- Do NOT add `on: push` — that would run tests on direct pushes to main too. The scope is PR visibility only; push coverage can be added in a later phase.
- The existing `claude-code-review.yml` uses `pull_request` with explicit `types:` — this workflow can omit `types:` for simplicity since we want all PR activity.

**Confidence:** HIGH — directly derived from project requirements.

### Permissions

**Recommendation: Minimal — omit explicit `permissions` block or use read-only**

```yaml
permissions:
  contents: read
```

Rationale:
- pytest only reads source files. No permission to write to pull requests, deploy, or access secrets is needed.
- Omitting `permissions` inherits the repository default (typically read-only for public repos, broader for private). Explicitly setting `contents: read` is the safest and most auditable choice.
- No `id-token: write` or `pull-requests: write` needed — this workflow does not post review comments or deploy.

**Confidence:** HIGH — standard security principle, no ambiguity.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Runner OS | `ubuntu-latest` | `windows-latest` | No Windows-specific code; slower provisioning; inconsistent with existing workflows |
| Runner OS | `ubuntu-latest` | `macos-latest` | 10x billing cost multiplier on GitHub Actions; no macOS-specific reason |
| Python setup | `actions/setup-python@v5` | `deadsnakes/action` or Docker container | No need for unusual Python builds; setup-python is the idiomatic, well-supported choice |
| Dep install | `pip install -r requirements.txt pytest` | `pip install pytest` only | Would break tests that import Flask/Werkzeug |
| Dep install | `pip install -r requirements.txt pytest` | `pip install .[test]` | No `pyproject.toml` or `setup.py` exists in repo |
| Caching | `cache: "pip"` in setup-python | `actions/cache@v4` manually | Built-in is simpler; same outcome |
| pytest flags | `-v` | `--tb=short` | Default traceback is fine; `-v` alone adds the most value per character |
| Trigger | `pull_request` | `pull_request` + `push` | PROJECT.md scopes this to PRs only |

---

## Canonical Workflow Skeleton

```yaml
name: pytest

on:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
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

This skeleton satisfies all five active requirements from PROJECT.md:
1. Runs pytest on every PR — `on: pull_request`
2. Results visible in PR checks UI — Actions natively reports job pass/fail; `-v` makes output readable
3. Does not block merging — no branch protection rules; workflow is informational only
4. Installs deps from `requirements.txt` — `pip install -r requirements.txt pytest`
5. Runs on Python 3.12 — `python-version: "3.12"`

---

## Sources

- Codebase inspection: `requirements.txt`, `tests/test_tasks.py`, `.github/workflows/claude-code-review.yml`, `.planning/PROJECT.md`
- Training knowledge (cutoff August 2025): `actions/setup-python` v5 release, pip caching behavior, pytest flags — **MEDIUM confidence**, web verification not available in this environment
- `actions/checkout@v4` confirmed in existing repo workflow — HIGH confidence
