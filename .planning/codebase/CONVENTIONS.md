# Coding Conventions

**Analysis Date:** 2026-03-23

## Naming Patterns

**Files:**
- `snake_case` for all Python modules: `tasks.py`, `storage.py`, `web.py`
- Test files prefixed with `test_`: `tests/test_tasks.py`
- Templates use `snake_case.html`: `templates/index.html`

**Functions:**
- `snake_case` for all functions: `load_tasks()`, `save_tasks()`, `get_next_id()`, `parse_tags()`
- Flask route functions named after the resource/action: `index`, `add`, `done`, `delete`, `edit`, `reorder`

**Variables:**
- `snake_case` throughout: `task_id`, `task_map`, `show_done`, `active_tag`, `all_tags`, `due_date`
- Loop variables use singular of the collection: `for task in tasks`, `for item in data`

**Types/Classes:**
- `PascalCase` for classes: `Task`
- Dataclass fields use `snake_case`: `created_at`, `due_date`

**URL Routes:**
- Lowercase with hyphens for multi-word resources (only single-word routes used currently): `/`, `/add`, `/done/<id>`, `/delete/<id>`, `/edit/<id>`, `/reorder`

## Code Style

**Formatting:**
- No autoformatter config detected (no `.prettierrc`, `pyproject.toml`, or `.flake8`)
- 4-space indentation (standard Python)
- Single blank line between functions within a file
- Two blank lines before top-level route functions (PEP 8)

**Linting:**
- No linter config detected; follow PEP 8 by convention

**String Quotes:**
- Double quotes for docstrings: `"""Split comma-separated string..."""`
- Double quotes for inline strings in general: `"medium"`, `"low"`, `"high"`

## Import Organization

**Order (as observed):**
1. Standard library imports (`sys`, `os`, `json`, `datetime`)
2. Third-party imports (`flask`, `werkzeug`)
3. Local module imports (`from tasks import Task`, `from storage import load_tasks, save_tasks`)

**Path manipulation:**
- `web.py` and `tests/test_tasks.py` both use `sys.path.insert(0, ...)` to make the project root importable — required because there is no package `__init__.py`

## Comments

**When to Comment:**
- Brief inline comments explain non-obvious decisions: `# IDs are assigned by incrementing the current maximum.`
- Comments explain intent for edge cases: `# Silently ignore submissions with an empty title.`
- Comments above class definitions describe lifecycle nuances: `# id is None until the task is persisted via save_tasks().`

**Docstrings:**
- Used only for utility functions with non-trivial behavior, not for route handlers
- Example from `web.py`:
  ```python
  def parse_tags(raw):
      """Split comma-separated string into a deduped, sorted list of lowercase tags."""
  ```

**No docstrings on:**
- Route functions (behavior is documented inline with comments)
- `Task` methods (`complete`, `__str__`)

## Model Design (`tasks.py`)

**Pattern:** Python `dataclass` with typed fields and defaults.

```python
@dataclass
class Task:
    title: str
    description: str = ""
    done: bool = False
    priority: str = "medium"  # valid values: "low", "medium", "high"
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    due_date: Optional[str] = None
    tags: list = field(default_factory=list)
    id: Optional[int] = None
```

- Required fields first (no default), optional fields after (with defaults)
- `id` is always last; it is `None` until assigned by `get_next_id()` at save time
- `created_at` uses ISO 8601 string, not a `datetime` object — keeps JSON serialization simple
- `due_date` uses ISO date string `YYYY-MM-DD` or `None`
- `tags` is always a sorted list of lowercase strings

**Methods on model:**
- Only behavioral methods go on `Task` — no persistence logic
- `complete()` is one-way (no undo): `self.done = True`
- `__str__` produces CLI-friendly output: `[x] (high) Buy milk`

## Storage Layer (`storage.py`)

**Pattern:** Module-level functions, no class, no caching.

- `load_tasks()` — reads `tasks.json`, returns `list[Task]`. Returns `[]` if file absent.
- `save_tasks(tasks)` — overwrites `tasks.json` with explicit field serialization (not `dataclasses.asdict()`), ensuring only known fields are written.
- `DATA_FILE` constant resolved relative to the module file using `os.path.abspath(__file__)`, not `cwd`.
- Every read/write operation goes to disk — no in-memory cache.

## Route Design (`web.py`)

**Pattern:** Thin Flask route functions — no service layer. Routes call `load_tasks()`/`save_tasks()` directly.

- All mutating routes (`/add`, `/done`, `/delete`, `/edit`, `/reorder`) use `POST` only
- After any mutation, routes redirect (Post/Redirect/Get pattern): `return redirect(url_for("index"))`
- `done` and `delete` redirect to `request.referrer` first to preserve query state, falling back to `url_for("index")`
- Missing task in `edit` redirects gracefully to index rather than 404
- JSON endpoint (`/reorder`) returns `"", 204` on success or `"Bad request", 400` on malformed input

**Helper functions in `web.py`:**
- `parse_tags(raw)` — pure function, no side effects
- `get_next_id(tasks)` — pure function, takes task list, returns int

## Template Design (`templates/index.html`)

- Single shared template for both list view and edit view
- Edit mode is signaled by the `editing` context variable (set to the `Task` object being edited, or absent/falsy for list view)
- Context variables passed to template: `tasks`, `show_done`, `active_tag`, `all_tags`, `draggable_enabled`, `today`, `editing` (optional)

## Priority Values

Valid priority strings (enforced by convention, not validated at runtime):
- `"low"`
- `"medium"` (default)
- `"high"`

---

*Convention analysis: 2026-03-23*
