# Codebase Structure

## Directory Layout

```
claude-demo/
├── tasks.py              # Core data model (Task dataclass)
├── storage.py            # Persistence layer (JSON read/write)
├── web.py                # Flask application — routes and request handling
├── tasks.json            # Runtime data file (git-ignored)
├── requirements.txt      # Python dependencies
├── Dockerfile            # Container image definition
├── docker-compose.yml    # Local multi-container orchestration
├── CLAUDE.md             # AI assistant instructions for this repo
├── README.md             # Project documentation
├── templates/
│   └── index.html        # Single shared Jinja2 template (list + edit views)
├── tests/
│   └── test_tasks.py     # Pytest unit tests
├── .github/
│   └── workflows/
│       ├── main.yml              # Main CI pipeline
│       ├── hello.yml             # Hello World workflow
│       ├── claude.yml            # Claude AI integration workflow
│       └── claude-code-review.yml # Automated code review workflow
└── .planning/            # GSD planning artifacts (git-ignored)
```

## File Responsibilities

### `tasks.py`
- Defines the `Task` dataclass: `id`, `title`, `description`, `done`, `priority`, `created_at`, `due_date`, `tags`
- `priority` is a string: `"low"`, `"medium"`, or `"high"`
- `id` is `None` until persisted; assigned by `web.py` via `get_next_id()`
- `complete()` method sets `done = True` (one-way, no undo)
- `__str__` produces CLI-friendly output: `[x] (high) Buy milk`

### `storage.py`
- `DATA_FILE` resolves to `tasks.json` relative to the module file (not cwd)
- `load_tasks()` — reads `tasks.json`, deserializes each dict into a `Task(**item)`; returns `[]` on first run
- `save_tasks(tasks)` — serializes task list to JSON with explicit field mapping (future-proof against dataclass changes)
- No caching; every operation reads/writes the full file

### `web.py`
- Flask app entry point; uses `ProxyFix` middleware for reverse proxy support
- **Routes:**
  - `GET /` — list tasks; accepts `?show_done=0` and `?tag=<name>` query params; passes `draggable_enabled` flag when no filters active
  - `POST /add` — create task; ignores empty titles; calls `get_next_id()`
  - `POST /done/<id>` — mark task complete; redirects to referrer
  - `POST /delete/<id>` — remove task; redirects to referrer
  - `GET|POST /edit/<id>` — GET renders edit form via shared template with `editing=task`; POST saves changes
  - `POST /reorder` — accepts JSON `{"order": [id, ...]}` for drag-and-drop reordering
- No service layer — routes call `load_tasks()`/`save_tasks()` directly
- Helper `parse_tags(raw)` splits comma-separated tag strings into sorted, deduplicated lowercase lists

### `templates/index.html`
- Single template shared for both list view and edit view
- `editing` context variable: `None` for list view, a `Task` object for edit view
- Renders task list, add form, filter controls (show_done toggle, tag chips), and inline edit form

### `tests/test_tasks.py`
- Pytest unit tests focused on the `Task` model

## Entry Points

- **Web server:** `python web.py` (debug mode, port 5000) or via Dockerfile/docker-compose
- **Tests:** `pytest` from project root

## How Components Interact

```
HTTP Request
    └─> web.py (Flask route)
            ├─> storage.load_tasks()  ──> tasks.json
            ├─> Task() / task.complete()  ──> tasks.py
            └─> storage.save_tasks()  ──> tasks.json
                      └─> render_template("index.html", ...)
```

No service layer exists between routes and storage — all business logic lives directly in route handlers.
