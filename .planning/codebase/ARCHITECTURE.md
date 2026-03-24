# Architecture

**Analysis Date:** 2026-03-24

## Pattern Overview

**Overall:** Flat 3-file MVC (no service layer)

**Key Characteristics:**
- No service layer — `web.py` calls storage directly
- No database — plain JSON file (`tasks.json`) read/written on every request
- Single template (`templates/index.html`) handles both list and edit views via `editing` context var

## Layers

| Layer | File | Responsibility |
|-------|------|----------------|
| Model | `tasks.py` | `Task` dataclass; field definitions; `complete()` method |
| Storage | `storage.py` | `load_tasks()` / `save_tasks()` — JSON serialization only |
| Web | `web.py` | Flask routes; business logic; calls storage directly |
| Template | `templates/index.html` | Renders list + inline edit form |

## Data Flow

**Read (GET /):**
1. `web.py` calls `load_tasks()` → reads `tasks.json` → returns `list[Task]`
2. Route filters by `show_done` and `tag` query params
3. `render_template("index.html", tasks=...)` returns HTML

**Write (POST /add, /done, /delete, /edit, /reorder):**
1. Route receives form data / JSON body
2. Calls `load_tasks()` to get current state
3. Mutates the list in memory
4. Calls `save_tasks(tasks)` → overwrites `tasks.json`
5. Redirects to index (or referrer)

## Key Abstractions

**Task (`tasks.py`):**
- Dataclass with fields: `id`, `title`, `description`, `priority`, `done`, `created_at`, `due_date`, `tags`
- `priority` values: `"low"`, `"medium"`, `"high"`
- `id` is `None` until persisted; assigned via `get_next_id()` in `web.py`
- `tags`: sorted list of lowercase strings

## Entry Points

**Web server:** `web.py` — `python web.py` or `flask run`; binds `0.0.0.0:5000`

**Routes:**
| Method | Path | Action |
|--------|------|--------|
| GET | `/` | List tasks; `?show_done=0`, `?tag=<tag>` filters |
| POST | `/add` | Create task |
| POST | `/done/<id>` | Mark complete |
| POST | `/delete/<id>` | Remove task |
| GET/POST | `/edit/<id>` | Show/submit edit form |
| POST | `/reorder` | Drag-drop reorder (JSON body `{"order": [...ids]}`) |

## Error Handling

- Missing task on edit/done/delete: silently skips or redirects to index
- Empty title on add/edit: silently ignored, no save performed
- Missing `tasks.json`: `load_tasks()` returns `[]` (first-run safe)

---

*Architecture analysis: 2026-03-24*
