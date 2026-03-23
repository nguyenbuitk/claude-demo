# Phase 1: pytest CI Workflow — Execution Plan

**Phase:** 01-pytest-ci-workflow
**Goal:** Every pull request automatically runs the test suite and shows pass/fail results in the GitHub PR checks UI
**Requirements:** TRIG-01, TRIG-02, ENV-01, ENV-02, ENV-03, DEP-01, DEP-02, TEST-01, TEST-02, TEST-03, CI-01, CI-02
**Plans:** 3 (01-01, 01-02, 01-03)
**Wave structure:**
- Wave 1: Plan 01-01 and Plan 01-02 (independent — no file overlap)
- Wave 2: Plan 01-03 (depends on 01-01 being merged or pushed to a branch)

---

## Plan 01-01: Write .github/workflows/test.yml

**Goal:** Create the GitHub Actions workflow file that triggers pytest on every pull request event, installs dependencies, and surfaces results in the PR checks UI with concurrency control.

**Requirements covered:** TRIG-01, TRIG-02, ENV-01, ENV-02, ENV-03, DEP-01, DEP-02, TEST-01, TEST-02, TEST-03, CI-01, CI-02

**Files:**
- `.github/workflows/test.yml` (new file)

### Tasks

**Task 1: Create .github/workflows/test.yml**

Create the file with the following exact content. Do not deviate from these specifications.

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

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: Install dependencies
        run: pip install -r requirements.txt pytest

      - name: Run tests
        run: pytest tests/ -v --tb=short
```

Implementation notes:
- `on: pull_request` (not `on: push`) — this is what makes results appear as a named check in the PR checks UI; push-to-main is explicitly out of scope for Phase 1 per STATE.md decision [Init]
- `types: [opened, synchronize, reopened]` — covers all three PR lifecycle events that should trigger a run; `synchronize` fires on every subsequent commit pushed to an open PR
- `concurrency.group: tests-${{ github.ref }}` — groups runs by branch ref so a new push to the same PR cancels the in-progress run from the prior commit; this satisfies success criterion 4
- `cancel-in-progress: true` — performs the actual cancellation; without this the group key has no effect
- Do NOT add `continue-on-error: true` anywhere — this would suppress failure signals and break the PR checks UI visibility
- `python-version: "3.12"` — explicit version string, not `"3.x"`, matches the production Dockerfile
- `cache: "pip"` — enables pip dependency caching via actions/setup-python's built-in cache support; reduces install time on repeated runs
- `pip install -r requirements.txt pytest` — single install command; pytest is NOT in requirements.txt (confirmed: requirements.txt contains only Flask, Werkzeug, Jinja2, gunicorn) so it must be installed explicitly; combining into one command avoids a second pip invocation
- `pytest tests/ -v --tb=short` — `-v` produces verbose output showing individual test names and pass/fail per TEST-02; `--tb=short` shows compact tracebacks per TEST-03; `tests/` targets the tests directory per TEST-01
- The workflow has no `permissions:` block — the default read-only GITHUB_TOKEN is sufficient for a test-only job; write permissions are only needed for GHCR push (Phase 2)
- The check name in the PR UI will appear as "Tests / test" (workflow name / job name); this is the "Tests" check referenced in success criterion 1

**Verification:**
- File exists at `.github/workflows/test.yml`
- YAML is valid: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/test.yml'))" && echo "YAML valid"`
- Workflow name is `Tests`, job name is `test`
- Trigger is `pull_request` with types `[opened, synchronize, reopened]`
- Concurrency block is present with `cancel-in-progress: true`
- Python version is exactly `"3.12"` (not `"3.x"`)
- Install step runs `pip install -r requirements.txt pytest` (single command, pytest explicit)
- Test step runs `pytest tests/ -v --tb=short`
- No `continue-on-error` anywhere in the file

**Acceptance Criteria:**
- `.github/workflows/test.yml` exists and is valid YAML
- All 12 requirements (TRIG-01 through CI-02) are satisfied by the workflow definition
- A failed test will exit non-zero and mark the check as failed in the PR UI
- The check does not prevent merging (no branch protection rules are configured by this workflow)

---

## Plan 01-02: Add conftest.py at repo root

**Goal:** Add a `conftest.py` at the repository root so pytest discovers the project root on the Python path automatically, eliminating the `sys.path.insert` boilerplate currently in `tests/test_tasks.py`.

**Requirements covered:** (supporting — enables clean test execution referenced by TEST-01, TEST-02, TEST-03)

**Files:**
- `conftest.py` (new file at repo root)
- `tests/test_tasks.py` (modify — remove sys.path boilerplate)

### Tasks

**Task 1: Create conftest.py at repo root**

Create `/conftest.py` (at repository root, not inside `tests/`) with the following content:

```python
# conftest.py — at repository root
# Placing conftest.py here causes pytest to add the repo root to sys.path
# automatically, so test files can import tasks, storage, web without any
# sys.path manipulation.
```

This file can be empty or contain only comments. Its presence at the root is what triggers pytest's rootdir detection and sys.path insertion. No imports, no fixtures, no code is required in this file for Phase 1.

Implementation notes:
- Location is critical: the file MUST be at the repository root (same level as `tasks.py`, `storage.py`, `web.py`), not inside the `tests/` subdirectory
- pytest walks upward from the test files to find `conftest.py`; finding it at the root causes pytest to add that directory to `sys.path`
- The file replaces the manual `sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))` pattern currently in `tests/test_tasks.py`
- Any future test files placed in `tests/` will inherit this path fix automatically without needing to repeat the boilerplate

**Task 2: Remove sys.path boilerplate from tests/test_tasks.py**

Edit `tests/test_tasks.py` to remove lines 1-3:

```python
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
```

The file after removal should begin with:

```python
from tasks import Task
```

The remaining test functions are unchanged. No other edits to this file.

**Verification:**
- `conftest.py` exists at the repository root
- `tests/test_tasks.py` no longer contains `sys.path.insert` or `import sys` or `import os`
- `pytest tests/ -v` passes (all 4 tests green) when run from the repository root
- Command: `cd /home/nguyenbui/own-repos/claude-demo && pytest tests/ -v --tb=short`
- Expected output: 4 tests collected, all pass (`PASSED`)

**Acceptance Criteria:**
- `conftest.py` exists at repo root with no functional code (comments only acceptable)
- `tests/test_tasks.py` imports `Task` directly without any path manipulation
- `pytest tests/ -v` exits 0 from the repo root
- No new test failures introduced

---

## Plan 01-03: Verify workflow on a test PR

**Goal:** Open a real pull request against the repository to confirm the workflow triggers, shows individual test names in the Actions log, and correctly reports pass/fail status in the PR checks UI.

**Wave:** 2 (depends on Plan 01-01 being committed and pushed to a branch)

**Depends on:** Plan 01-01 (test.yml must exist on the branch being merged)

**Files:** No new files — verification only

### Tasks

**Task 1: Push plans to a branch and open a PR**

This is a `checkpoint:human-action` task — GitHub PR creation requires human interaction with the GitHub web UI or CLI, and the test run result must be observed in the PR checks UI by a human.

Steps:
1. Confirm Plans 01-01 and 01-02 are committed on the current branch (or a dedicated branch, e.g., `feat/pytest-ci`)
2. Push the branch to GitHub: `git push origin <branch-name>`
3. Open a pull request against `main` (via `gh pr create` or the GitHub web UI)
4. Wait for the "Tests / test" check to appear in the PR checks section (typically within 30 seconds of opening the PR)

What to look for once the run starts:
- The check name "Tests" (or "Tests / test") appears in the PR checks list
- Clicking "Details" opens the GitHub Actions run log
- In the log under "Run tests", individual test names are visible with PASSED/FAILED markers:
  ```
  tests/test_tasks.py::test_task_creation PASSED
  tests/test_tasks.py::test_task_complete PASSED
  tests/test_tasks.py::test_task_str_incomplete PASSED
  tests/test_tasks.py::test_task_str_complete PASSED
  ```
- The overall check shows a green checkmark when all 4 pass

**Task 2: Verify failure behavior**

Temporarily introduce a deliberate test failure to confirm the PR check turns red without blocking the merge button.

Steps:
1. On the same branch, edit `tests/test_tasks.py` to add a failing assertion to one test (e.g., `assert task.done == True` on a newly created task)
2. Push the commit to the open PR
3. Confirm the "Tests" check re-triggers automatically (success criterion 4 — concurrency cancels the prior run if still in progress)
4. Confirm the check turns red (failed) in the PR checks UI
5. Confirm the "Merge pull request" button is still enabled (not greyed out) — no branch protection rule blocks merge
6. Revert the deliberate failure: remove the broken assertion and push again
7. Confirm the check turns green again

**Task 3: Human sign-off on all success criteria**

Confirm all five phase success criteria are visibly satisfied before closing this plan:

| # | Success Criterion | How to verify |
|---|-------------------|---------------|
| 1 | Opening or pushing to a PR automatically triggers a "Tests" check | Observed in PR checks UI — no manual trigger needed |
| 2 | Individual test names and pass/fail visible in Actions log | Confirmed in Actions log (Step 1 of Task 1 above) |
| 3 | Failed test → check shows failed, but merge not blocked | Confirmed via deliberate failure in Task 2 |
| 4 | New commit to open PR cancels in-progress run from prior commit | Push the revert commit while Task 2 run is in progress; confirm prior run shows "Cancelled" |
| 5 | Workflow completes using Python 3.12 with all deps installed | Visible in Actions log: setup-python step shows "3.12.x", install step exits 0 |

**Verification:**
- All five success criteria confirmed and checked off in the table above
- The PR checks UI shows a green "Tests" check after the final green run
- No `continue-on-error: true` was used (test failures propagated correctly in Task 2)

**Acceptance Criteria:**
- All five phase success criteria from ROADMAP.md are confirmed TRUE by direct observation
- The test.yml workflow file is the only mechanism driving the check — no other configuration was required

---

## Phase Success Criteria

From ROADMAP.md Phase 1:

1. Opening or pushing to a pull request automatically triggers a "Tests" check in the PR checks UI without any manual action
2. The check shows individual test names and pass/fail status in the GitHub Actions log (verbose output)
3. A failed test causes the check to show as failed in the PR UI, but does not block the merge button
4. A new commit pushed to an open PR cancels the in-progress run from the previous commit
5. The workflow completes using Python 3.12 with all app dependencies installed, matching the production runtime

## Requirement Coverage

| Requirement | Description | Plan | Task |
|-------------|-------------|------|------|
| TRIG-01 | Workflow runs on every PR (opened, synchronize, reopened) | 01-01 | Task 1 |
| TRIG-02 | Workflow does not block merging — visibility only | 01-01 | Task 1 |
| ENV-01 | Runs on ubuntu-latest runner | 01-01 | Task 1 |
| ENV-02 | Sets up Python 3.12 explicitly | 01-01 | Task 1 |
| ENV-03 | pip dependency cache enabled | 01-01 | Task 1 |
| DEP-01 | App dependencies from requirements.txt installed | 01-01 | Task 1 |
| DEP-02 | pytest installed explicitly (absent from requirements.txt) | 01-01 | Task 1 |
| TEST-01 | pytest runs against the tests/ directory | 01-01 | Task 1 |
| TEST-02 | Verbose output (-v) shows individual test names | 01-01 | Task 1 |
| TEST-03 | Short tracebacks (--tb=short) for readability | 01-01 | Task 1 |
| CI-01 | Concurrency group cancels stale runs on same PR | 01-01 | Task 1 |
| CI-02 | Workflow lives in a new dedicated file (test.yml) | 01-01 | Task 1 |

All 12 Phase 1 requirements are covered by Plan 01-01, Task 1.
Plans 01-02 and 01-03 are supporting work (path fix + live verification).
