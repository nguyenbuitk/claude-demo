# Codebase Structure

**Analysis Date:** 2026-03-24

## Directory Layout

```
claude-demo/
├── tasks.py             # Task dataclass (model)
├── storage.py           # JSON load/save helpers
├── web.py               # Flask app + all routes
├── tasks.json           # Runtime data file (committed, auto-overwritten)
├── conftest.py          # Pytest root config
├── requirements.txt     # Python dependencies
├── Dockerfile           # Container build
├── docker-compose.yml   # Local container orchestration
├── templates/
│   └── index.html       # Single Jinja2 template (list + edit)
├── tests/
│   └── test_tasks.py    # Unit tests
├── .github/
│   └── workflows/       # CI workflow YAMLs
└── .planning/           # GSD planning docs (not app code)
    └── codebase/
```

## Key File Locations

| Purpose | Path |
|---------|------|
| Data model | `tasks.py` |
| Persistence | `storage.py` |
| Web app / routes | `web.py` |
| HTML template | `templates/index.html` |
| Unit tests | `tests/test_tasks.py` |
| Test config | `conftest.py` |
| Runtime data | `tasks.json` |
| Dependencies | `requirements.txt` |

## Naming Conventions

- **Python files:** `snake_case.py`
- **Functions:** `snake_case` (e.g. `load_tasks`, `save_tasks`, `get_next_id`, `parse_tags`)
- **Classes:** `PascalCase` (e.g. `Task`)
- **Templates:** `snake_case.html` under `templates/`
- **Tests:** `test_<module>.py` in `tests/`

## Where to Add New Code

| What | Where |
|------|-------|
| New Task fields | `tasks.py` (dataclass) + `storage.py` (serialize dict) |
| New route | `web.py` (new `@app.route`) |
| New template | `templates/` |
| New tests | `tests/test_<module>.py` |
| New helper module | Project root (flat layout) |

## Special Files

- `tasks.json` — generated at runtime; committed to repo as seed data; overwritten on every mutation
- `conftest.py` — root-level pytest config; adds project root to `sys.path`
- `.planning/` — GSD planning docs; not application code

---

*Structure analysis: 2026-03-24*
