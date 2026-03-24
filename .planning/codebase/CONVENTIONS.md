# Coding Conventions

**Analysis Date:** 2026-03-24

## Naming Patterns

| Target | Pattern | Example |
|--------|---------|---------|
| Files | `snake_case.py` | `storage.py`, `tasks.py` |
| Functions | `snake_case` | `load_tasks()`, `parse_tags()`, `get_next_id()` |
| Variables | `snake_case` | `task_map`, `active_tag`, `due_date` |
| Classes | `PascalCase` | `Task` |
| Constants | `UPPER_SNAKE` | `DATA_FILE` |
| URL routes | `kebab-case` via Flask | `/done/<id>`, `/edit/<id>` |

## Code Style

- **No formatter config** detected (no `.flake8`, `pyproject.toml`, or `setup.cfg`)
- Standard PEP 8 indentation (4 spaces)
- Single quotes for strings inside comprehensions, double quotes elsewhere
- Trailing-comma style: multi-line dicts use trailing commas in `save_tasks()`

## Import Organization

1. stdlib (`json`, `os`, `sys`, `datetime`)
2. third-party (`flask`, `werkzeug`)
3. local (`tasks`, `storage`)

- `sys.path.insert(0, ...)` used in `web.py` for direct execution; `conftest.py` handles test path automatically

## Comments

- Inline `#` comments explain *why*, not what: `# Gaps are intentional — deleted task IDs are never reused.`
- Block comments above functions without docstrings (most internal helpers)
- Docstrings (`"""..."""`) used only on public utility functions: `parse_tags()` in `web.py`
- Method comments inside body, not as docstrings: `tasks.py` `complete()` and `__str__()`

## Error Handling

- **No exceptions raised or caught** in application code
- Silent fallback pattern: empty title is silently ignored in `POST /add` and `POST /edit`
- Missing task falls back to redirect: `next((t for t in tasks if t.id == task_id), None)` + redirect
- Bad JSON body in `/reorder` returns `"Bad request", 400`
- Missing `tasks.json` returns `[]` (no exception)

## Data Modeling

- `Task` is a `@dataclass` with typed fields (`tasks.py`)
- Optional fields use `Optional[str] = None`
- Mutable defaults use `field(default_factory=...)`
- Priority is an unvalidated string: `"low"`, `"medium"`, `"high"`

## Function Design

- Small, single-purpose functions (all under 15 lines)
- No service layer — `web.py` calls `load_tasks()`/`save_tasks()` directly
- Helper functions (`parse_tags`, `get_next_id`) are module-level, not methods

---

*Convention analysis: 2026-03-24*
