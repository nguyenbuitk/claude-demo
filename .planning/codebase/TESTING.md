# Testing Patterns

**Analysis Date:** 2026-03-24

## Test Framework

- **Runner:** pytest (installed via CI: `pip install pytest`, no version pin)
- **Assertion:** plain `assert` statements (no assertion library)
- **Config:** no `pytest.ini` or `pyproject.toml` — defaults only
- `conftest.py` at repo root adds root to `sys.path` for imports

**Run Commands:**
```bash
pytest                          # all tests
pytest tests/test_tasks.py::test_task_creation  # single test
pytest tests/ -v --tb=short     # CI mode (verbose, short tracebacks)
```

## Test File Organization

- Location: `tests/` directory, separate from source
- Naming: `test_<module>.py` (e.g., `tests/test_tasks.py`)
- No subdirectories yet

## Test Structure

```python
from tasks import Task

def test_task_creation():
    task = Task(title="Buy groceries", priority="high")
    assert task.title == "Buy groceries"
    assert task.done == False
    assert task.priority == "high"
```

- No classes/suites — flat `def test_*()` functions only
- No `setUp`/`tearDown` — each test constructs its own objects
- One logical assertion group per test function

## Mocking

- **None used** — no `unittest.mock`, `pytest-mock`, or monkeypatching
- `storage.py` and `web.py` routes are not tested (untested I/O)

## Fixtures

- **None defined** — no `@pytest.fixture` in `conftest.py` or test files
- Test data is constructed inline in each test

## Coverage

- **No coverage tooling** configured or enforced
- No `pytest-cov` in `requirements.txt`

## Test Types

| Type | Status |
|------|--------|
| Unit (dataclass logic) | Present — `tests/test_tasks.py` |
| Integration (storage I/O) | Absent |
| Route/HTTP | Absent |
| E2E | Absent |

## What Is Tested

- `Task` dataclass field defaults: `tests/test_tasks.py::test_task_creation`
- `Task.complete()` method: `tests/test_tasks.py::test_task_complete`
- `Task.__str__()` incomplete: `tests/test_tasks.py::test_task_str_incomplete`
- `Task.__str__()` complete: `tests/test_tasks.py::test_task_str_complete`

## CI Integration

- Runs on PRs via `.github/workflows/test.yml`
- Python 3.12, pip cache enabled
- Command: `pytest tests/ -v --tb=short`

---

*Testing analysis: 2026-03-24*
