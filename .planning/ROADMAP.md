# Roadmap: Claude Demo — CI/CD Pipeline

## Overview

This project adds automated pytest execution to a Flask task manager app. A single GitHub Actions workflow file triggers on every pull request, runs the test suite against Python 3.12, and surfaces pass/fail results in the PR checks UI. Scope is visibility-only — no merge gating, no coverage reporting, no deployment automation. The entire deliverable is one YAML file (and an optional conftest.py), so the roadmap is a single phase.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: pytest CI Workflow** - Create .github/workflows/test.yml so every PR shows test results (completed 2026-03-23)
- [ ] **Phase 2: Docker CI Pipeline** - Build and push Docker image to GHCR on merge to main, gated behind passing tests
- [ ] **Phase 3: Deadline Highlighting** - Highlight overdue tasks red and soon-due tasks amber in the task list
- [ ] **Phase 4: Completion History** - Record completion timestamps and expose a read-only history view

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
- [x] 01-01: Write .github/workflows/test.yml (trigger, env, deps, test execution, concurrency)
- [ ] 01-02: Add conftest.py at repo root to eliminate sys.path boilerplate from test files
- [ ] 01-03: Verify workflow runs correctly on a test PR and all success criteria are met

### Phase 2: Docker CI Pipeline
**Goal**: Every merge to main automatically builds a Docker image and pushes it to GHCR, but only after tests pass
**Depends on**: Phase 1 (test job must exist before build-and-push gates on it)
**Parallel**: Yes (DevOps workstream — independent of Phases 3 and 4)
**Requirements**: CI-01, CI-02, CI-03, CI-04, CI-05, CI-06, CI-07
**Success Criteria** (what must be TRUE):
  1. A pull request triggers the test job and the result appears in the PR checks UI; the build-and-push job does not run on PRs
  2. Merging to main triggers both jobs: test runs first, build-and-push runs only after test passes
  3. A failed test on main prevents the Docker build from running
  4. After a successful merge, `ghcr.io/nguyenbuitk/claude-demo:latest` and `ghcr.io/nguyenbuitk/claude-demo:sha-<commit>` are both present in the GHCR registry
  5. The workflow authenticates to GHCR using only `GITHUB_TOKEN` — no manually created secrets required
**Plans**: 3 plans

Plans:
- [ ] 02-01-PLAN.md — Write .github/workflows/ci.yml (test + build-and-push jobs)
- [ ] 02-02-PLAN.md — Verify ci.yml locally (YAML lint + all 7 requirement checks)
- [ ] 02-03-PLAN.md — Human verification (open PR, merge to main, verify GHCR tags)

**Files touched**: `.github/workflows/ci.yml` (new)

### Phase 3: Deadline Highlighting
**Goal**: Users can see at a glance which tasks are overdue or due soon without reading every due date
**Depends on**: Nothing (presentational only — no data model changes, no dependency on Phase 2 or 4)
**Parallel**: Yes (Dev 1 workstream — independent of Phases 2 and 4)
**Requirements**: HL-01, HL-02, HL-03, HL-04, HL-05
**Success Criteria** (what must be TRUE):
  1. A task whose due date is before today and is not done has a red row background (`#fde8e8`) in the task list
  2. A task due today or within the next 3 days (and not done) has an amber row background (`#fff3cd`)
  3. A task with no due date has no background color change
  4. A completed task (`done=True`) has no highlight regardless of its due date, including if it is overdue
  5. A task due exactly today shows amber (soon-due), not red (overdue)
**Plans**: TBD
**Files touched**: `web.py` (Jinja2 filter registration, `today_plus_3` in route context), `templates/index.html` (CSS classes, row logic)
**UI hint**: yes

### Phase 4: Completion History
**Goal**: Users can view a chronological log of all completed tasks with their completion timestamps
**Depends on**: Nothing (owns its own data model and route — independent of Phases 2 and 3)
**Parallel**: Yes (Dev 2 workstream — independent of Phases 2 and 3)
**Requirements**: HI-01, HI-02, HI-03, HI-04, HI-05, HI-06, HI-07, HI-08, HI-09
**Success Criteria** (what must be TRUE):
  1. Completing a task records the current timestamp in `completed_at`; restarting the server and visiting `/history` still shows that timestamp (it is persisted to `tasks.json`)
  2. Loading the app with an existing `tasks.json` that has no `completed_at` field does not crash — legacy tasks appear in the history with "—" for the timestamp
  3. `GET /history` shows all completed tasks sorted with the most recently completed first
  4. Each row in the history view displays title, priority, due date, completed-at timestamp (or "—"), and tags
  5. The history page has no Done, Edit, or Delete buttons — it is read-only
  6. A "History" link in the page header navigates to `/history` from any page
**Plans**: TBD
**Files touched**: `tasks.py` (`completed_at` field, `complete()` method), `storage.py` (serializer update), `web.py` (`/history` route), `templates/history.html` (new), `templates/index.html` (nav link)
**UI hint**: yes

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
| CI-01 | ci.yml contains both test and build-and-push jobs | 02-01 |
| CI-02 | test job runs on every PR and push to main | 02-01 |
| CI-03 | build-and-push runs only after test passes (needs: test) | 02-01 |
| CI-04 | build-and-push only triggers on push to main, not PRs | 02-01 |
| CI-05 | Docker image pushed to ghcr.io/nguyenbuitk/claude-demo | 02-01 |
| CI-06 | Image tagged with latest and sha-<commit-sha> | 02-01 |
| CI-07 | GHCR auth via GITHUB_TOKEN with packages: write | 02-01 |
| HL-01 | Overdue tasks (due_date < today, not done) highlighted red | Phase 3 |
| HL-02 | Soon-due tasks (due within 3 days, not done) highlighted amber | Phase 3 |
| HL-03 | Tasks with no due_date have no highlight | Phase 3 |
| HL-04 | Completed tasks (done=True) have no highlight regardless of due_date | Phase 3 |
| HL-05 | Tasks due today highlighted amber, not red | Phase 3 |
| HI-01 | completed_at field added to Task dataclass | Phase 4 |
| HI-02 | Task.complete() writes ISO timestamp to completed_at | Phase 4 |
| HI-03 | storage.py serializes and persists completed_at | Phase 4 |
| HI-04 | Loading old tasks.json without completed_at does not crash | Phase 4 |
| HI-05 | GET /history shows all completed tasks | Phase 4 |
| HI-06 | History sorted by completed_at descending | Phase 4 |
| HI-07 | History rows show title, priority, due_date, completed_at, tags | Phase 4 |
| HI-08 | "History" link added to index.html header | Phase 4 |
| HI-09 | History page is read-only (no Done/Edit/Delete buttons) | Phase 4 |

**Coverage: 12/12 v1 requirements mapped (Phase 1) + 21/21 v1 requirements mapped (Phases 2-4).**

## Plan Dependencies

```
01-01: Write test.yml (no dependencies — this is the core deliverable)
   |
   └── 01-02: Add conftest.py (no hard dependency on 01-01 but logically follows)
         |
         └── 01-03: Verify on a real PR (depends on 01-01 being merged or in a branch)

02-01: Write ci.yml (no dependencies within phase)
   |
   └── 02-02: Verify ci.yml locally (depends on 02-01)
         |
         └── 02-03: Human verification on GitHub (depends on 02-02)

Phase 2 (DevOps)   ─── parallel ───┐
Phase 3 (Dev 1)    ─── parallel ───┤── all independent, merge DevOps first
Phase 4 (Dev 2)    ─── parallel ───┘
```

01-02 is independent of 01-01 at the file level but should be done alongside or immediately after to prevent sys.path boilerplate from spreading to any new test files written during verification.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. pytest CI Workflow | 1/1 | Complete   | 2026-03-23 |
| 2. Docker CI Pipeline | 0/3 | Not started | - |
| 3. Deadline Highlighting | 0/2 | Not started | - |
| 4. Completion History | 0/3 | Not started | - |
