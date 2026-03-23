# Requirements: Claude Demo — CI/CD Pipeline

**Defined:** 2026-03-23
**Core Value:** Every PR shows test results so regressions are caught before they reach main.

## v1 Requirements

### Workflow Trigger

- [ ] **TRIG-01**: Workflow runs automatically on every pull request (opened, synchronize, reopened)
- [ ] **TRIG-02**: Workflow does not block merging — results are visible in PR checks UI only

### Environment Setup

- [ ] **ENV-01**: Workflow runs on `ubuntu-latest` runner
- [ ] **ENV-02**: Workflow sets up Python 3.12 explicitly (matching the Dockerfile and production runtime)
- [ ] **ENV-03**: pip dependency cache is enabled to speed up repeated runs

### Dependency Installation

- [ ] **DEP-01**: All app dependencies from `requirements.txt` are installed (Flask, Werkzeug, Jinja2, Gunicorn)
- [ ] **DEP-02**: `pytest` is installed explicitly (it is not in `requirements.txt`)

### Test Execution

- [ ] **TEST-01**: `pytest` runs against the `tests/` directory
- [ ] **TEST-02**: Test output is verbose (`-v`) so individual test names and results are visible in the Actions log
- [ ] **TEST-03**: Tracebacks use short format (`--tb=short`) for readability

### CI Hygiene

- [ ] **CI-01**: A concurrency group cancels in-progress runs when a new commit is pushed to the same PR
- [ ] **CI-02**: Workflow is defined in a new, dedicated file (`.github/workflows/test.yml`) — not merged into existing workflows

## v2 Requirements

### Test Coverage

- **COV-01**: Coverage report generated on each CI run (`pytest-cov`)
- **COV-02**: Coverage results uploaded as a PR check annotation or artifact

### Test Expansion

- **EXP-01**: Tests for `storage.py` with proper file I/O isolation (`tmp_path` / `monkeypatch`)
- **EXP-02**: HTTP-level tests for Flask routes using the Flask test client
- **EXP-03**: `conftest.py` added to centralise `sys.path` setup (currently per-file in `test_tasks.py`)

### Enforcement

- **ENF-01**: Branch protection rule requiring the `Tests` check to pass before merge

## Out of Scope

| Feature | Reason |
|---------|--------|
| Docker image build/push in CI | Separate concern; pipeline is test-only for now |
| Deployment automation | Deferred; focus is test visibility first |
| Multi-version Python matrix | App targets exactly Python 3.12; matrix adds noise |
| JUnit XML + test-reporter action | Marketplace dependency; defer to v2 |
| Slack/email failure notifications | PR checks UI is sufficient for v1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TRIG-01 | Phase 1 | Pending |
| TRIG-02 | Phase 1 | Pending |
| ENV-01 | Phase 1 | Pending |
| ENV-02 | Phase 1 | Pending |
| ENV-03 | Phase 1 | Pending |
| DEP-01 | Phase 1 | Pending |
| DEP-02 | Phase 1 | Pending |
| TEST-01 | Phase 1 | Pending |
| TEST-02 | Phase 1 | Pending |
| TEST-03 | Phase 1 | Pending |
| CI-01 | Phase 1 | Pending |
| CI-02 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-23 after initial definition*
