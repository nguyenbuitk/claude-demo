# Testing

**Analysis Date:** 2026-03-23

## Framework

- **pytest** (via `requirements.txt`)
- No test configuration file (`pytest.ini`, `pyproject.toml [tool.pytest]`, or `setup.cfg` not present)
- Tests run from project root: `pytest` or `pytest tests/test_tasks.py::test_name`

## Test Location

```
tests/
└── test_tasks.py   # 4 unit tests for the Task dataclass
```

No `__init__.py` in `tests/`. The test file manually inserts the project root into `sys.path` to import `tasks.py`.

## What Is Tested

### `tests/test_tasks.py` — Task model only

| Test | What it checks |
|------|---------------|
| `test_task_creation` | Field defaults: `title`, `done=False`, `priority` |
| `test_task_complete` | `task.complete()` sets `done = True` |
| `test_task_str_incomplete` | `__str__` format for incomplete task: `[ ] (low) Fix bug` |
| `test_task_str_complete` | `__str__` format for complete task: `[x] (low) Fix bug` |

## What Is NOT Tested

### `storage.py` — No tests
- `load_tasks()` — file read, JSON deserialization, empty list on missing file
- `save_tasks()` — JSON serialization, field mapping, file write
- Round-trip: save then load produces equivalent tasks
- Edge cases: malformed JSON, missing fields, unknown fields

### `web.py` — No tests
- No route tests (no Flask test client usage)
- `GET /` — list rendering, `show_done` filter, `tag` filter
- `POST /add` — task creation, empty title ignore, tag parsing
- `POST /done/<id>` — completion, referrer redirect
- `POST /delete/<id>` — deletion, missing ID handling
- `GET|POST /edit/<id>` — edit form rendering, save, missing task redirect
- `POST /reorder` — JSON order persistence, bad request handling
- `parse_tags()` helper — deduplication, lowercasing, sorting
- `get_next_id()` helper — empty list, ID gap handling

### Integration — No tests
- End-to-end: HTTP request → storage → response
- No fixture for temporary `tasks.json`

## Coverage Gaps Summary

| Layer | Coverage |
|-------|----------|
| `tasks.py` (model) | ~80% — missing: `due_date`/`tags` field tests, `id=None` default |
| `storage.py` | 0% |
| `web.py` (routes) | 0% |
| `web.py` (helpers) | 0% |

## CI Status

No CI job currently runs `pytest`. The `.github/workflows/main.yml` workflow exists but does not execute the test suite. Test runs are manual only.

## How to Run Tests

```bash
# All tests
pytest

# Single test
pytest tests/test_tasks.py::test_task_creation

# With output
pytest -v
```
