# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
pytest

# Run a single test
pytest tests/test_tasks.py::test_task_creation

# Run the web app (Flask, port 5000)
python web.py
```

## Architecture

- **`tasks.py`** — `Task` dataclass (title, description, priority, done, created_at, id). Priority values: `"low"`, `"medium"`, `"high"`.
- **`storage.py`** — `load_tasks()` / `save_tasks()` persisting to `tasks.json` in the working directory. Plain JSON read/write on every operation; no database.
- **`web.py`** — Flask app. Routes: `GET /`, `POST /add`, `POST /done/<id>`, `POST /delete/<id>`, `GET|POST /edit/<id>`. The `GET /` route accepts a `?show_done=0` query param to filter completed tasks. Template at `templates/index.html` (shared for both list and edit views via an `editing` context variable).

Task IDs are assigned by finding the current max ID and incrementing. There is no service layer — `web.py` calls `load_tasks()`/`save_tasks()` directly.

## Git Workflow

**Branching strategy:** Each GSD phase uses a feature branching model. Branch names follow `gsd/phase-{N}-{slug}` (e.g., `gsd/phase-02-ci-cd-pipeline`). Quick tasks may commit directly to main.

**Pull requests:** When a phase is complete, open a pull request from the phase branch to main. Use the template at `.github/pull_request_template.md`. PRs should be reviewed before merging.

**Commit conventions:** Conventional commits with scope:
- `feat(phase-plan):` -- new features
- `fix(phase-plan):` -- bug fixes
- `docs(phase-plan):` -- documentation
- `test(phase):` -- test additions
- `chore(phase):` -- config/tooling

**Do NOT push directly to main** for phase work. Quick tasks (config, docs) are the exception.
