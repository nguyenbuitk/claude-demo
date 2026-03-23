# Roadmap: Claude Demo — CI/CD Pipeline

## Overview

This project adds automated pytest execution to a Flask task manager app. A single GitHub Actions workflow file triggers on every pull request, runs the test suite against Python 3.12, and surfaces pass/fail results in the PR checks UI. Scope is visibility-only — no merge gating, no coverage reporting, no deployment automation. The entire deliverable is one YAML file (and an optional conftest.py), so the roadmap is a single phase.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: pytest CI Workflow** - Create .github/workflows/test.yml so every PR shows test results

## Phase Details

### Phase 1: pytest CI Workflow
**Goal**: Every pull request automatically runs the test suite and shows pass/fail results in the GitHub PR checks UI
**Depends on**: Nothing (first phase)
**Requirements**: TRIG-01, TRIG-02, ENV-01, ENV-02, ENV-03, DEP-01, DEP-02, TEST-01, TEST-02, TEST-03, CI-01, CI-02
**Success Criteria** (what must be TRUE):
  1. Opening or pushing to a pull request automatically triggers a "Tests" check in the PR checks UI without any manual action
  2. The check shows individual test names and pass/fail status in the GitHub Actions log (verbose output)
  3. A failed test causes the check to show as failed in the PR UI, but does not block the merge button
  4. A new commit pushed to an open PR cancels the in-progress run from the previous commit
  5. The workflow completes using Python 3.12 with all app dependencies installed, matching the production runtime
**Plans**: 3 plans

Plans:
- [ ] 01-01: Write .github/workflows/test.yml (trigger, env, deps, test execution, concurrency)
- [ ] 01-02: Add conftest.py at repo root to eliminate sys.path boilerplate from test files
- [ ] 01-03: Verify workflow runs correctly on a test PR and all success criteria are met

## Requirement Coverage

| Requirement | Description | Plan |
|-------------|-------------|------|
| TRIG-01 | Workflow runs on every PR (opened, synchronize, reopened) | 01-01 |
| TRIG-02 | Workflow does not block merging — visibility only | 01-01 |
| ENV-01 | Runs on ubuntu-latest runner | 01-01 |
| ENV-02 | Sets up Python 3.12 explicitly | 01-01 |
| ENV-03 | pip dependency cache enabled | 01-01 |
| DEP-01 | App dependencies from requirements.txt installed | 01-01 |
| DEP-02 | pytest installed explicitly (absent from requirements.txt) | 01-01 |
| TEST-01 | pytest runs against the tests/ directory | 01-01 |
| TEST-02 | Verbose output (-v) shows individual test names | 01-01 |
| TEST-03 | Short tracebacks (--tb=short) for readability | 01-01 |
| CI-01 | Concurrency group cancels stale runs on same PR | 01-01 |
| CI-02 | Workflow lives in a new dedicated file (test.yml) | 01-01 |

**Coverage: 12/12 v1 requirements mapped.**

## Plan Dependencies

```
01-01: Write test.yml (no dependencies — this is the core deliverable)
   |
   └── 01-02: Add conftest.py (no hard dependency on 01-01 but logically follows)
         |
         └── 01-03: Verify on a real PR (depends on 01-01 being merged or in a branch)
```

01-02 is independent of 01-01 at the file level but should be done alongside or immediately after to prevent sys.path boilerplate from spreading to any new test files written during verification.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. pytest CI Workflow | 0/3 | Not started | - |
