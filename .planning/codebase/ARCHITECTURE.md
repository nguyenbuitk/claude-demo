# Architecture

**Analysis Date:** 2026-03-23

## Pattern Overview

**Overall:** Flat, two-layer Flask web application with no service layer.

**Key Characteristics:**
- No service or business-logic layer — `web.py` route handlers call `storage.py` functions directly
- All state is persisted to a single JSON file (`tasks.json`); no database
- Every route performs a full read-then-write cycle; no in-memory state between requests
- A single Jinja2 template (`templates/index.html`) serves both the list view and the edit view, distinguished by an `editing` context variable

## Layers

**Data Model:**
- Purpose: Define the structure of a task and provide one behavior method
- Location: `tasks.py`
- Contains: `Task` dataclass with fields: `id`, `title`, `description`, `done`, `priority`, `created_at`, `due_date`, `tags`; one method: `complete()`
- Depends on: Python standard library only (`dataclasses`, `datetime`, `typing`)
- Used by: `storage.py` (reconstruction), `web.py` (instantiation), `tests/test_tasks.py`

**Persistence Layer:**
- Purpose: Read/write tasks from/to disk
- Location: `storage.py`
- Contains: `load_tasks()` and `save_tasks(tasks)` functions
- Depends on: `tasks.py` (Task class), `json`, `os`
- Used by: `web.py` (every route invokes both functions)

**Web Layer:**
- Purpose: HTTP routing, request parsing, response rendering
- Location: `web.py`
- Contains: Flask app, six route handlers, two helper functions (`parse_tags`, `get_next_id`)
- Depends on: `tasks.py`, `storage.py`, Flask, Werkzeug

**Template Layer:**
- Purpose: HTML rendering for both list and edit views
- Location: `templates/index.html`
- Contains: Jinja2 template with embedded CSS and conditional JavaScript (drag-and-drop)
- Depends on: context variables passed by `web.py` route handlers

## Data Flow

**Add Task:**

1. Browser submits `POST /add` with form fields: `title`, `description`, `priority`, `due_date`, `tags`
2. `add()` in `web.py` calls `load_tasks()` to fetch current task list from `tasks.json`
3. `get_next_id(tasks)` computes `max(existing ids) + 1`
4. A new `Task` object is instantiated and appended to the list
5. `save_tasks(tasks)` serializes the full list back to `tasks.json`
6. Handler redirects to `GET /`

**Complete Task:**

1. Browser submits `POST /done/<id>`
2. `done()` calls `load_tasks()`, finds the task by id, calls `task.complete()` (sets `done=True`)
3. `save_tasks(tasks)` rewrites the file
4. Handler redirects back to referrer (or `/`)

**Edit Task (GET):**

1. Browser navigates to `GET /edit/<id>`
2. `edit()` calls `load_tasks()`, finds the task, renders `index.html` with `editing=task`
3. Template detects `editing` is truthy and renders the form pre-filled with current task fields

**Edit Task (POST):**

1. Browser submits `POST /edit/<id>` with updated form fields
2. `edit()` mutates the found `Task` object in-place, calls `save_tasks(tasks)`
3. Redirects to `GET /`

**Reorder Tasks:**

1. Browser drag-and-drop triggers `fetch POST /reorder` with JSON body `{"order": [id, ...]}`
2. `reorder()` rebuilds the task list in the supplied order; tasks not in the payload are appended
3. `save_tasks(reordered)` persists new order; responds `204 No Content`

**Delete Task:**

1. Browser submits `POST /delete/<id>`
2. `delete()` calls `load_tasks()`, filters out the matching id, calls `save_tasks()`
3. Redirects back to referrer (or `/`)

**State Management:**
- No server-side session or in-memory state; the `tasks.json` file is the sole source of truth
- View state (show_done, active_tag) is carried entirely via query parameters (`?show_done=1&tag=foo`)

## Key Abstractions

**Task:**
- Purpose: Represents a single to-do item
- Examples: `tasks.py` (lines 8-26)
- Pattern: Python `@dataclass`; `id` is `None` until persisted; `priority` is a plain string constrained to `"low"`, `"medium"`, `"high"` by convention only (no enum)

**load_tasks / save_tasks:**
- Purpose: Full-file read and full-file overwrite on every operation
- Examples: `storage.py` (lines 10-40)
- Pattern: Stateless functions; no connection pooling or caching; JSON deserialization reconstructs `Task` objects via `Task(**item)` (requires JSON fields to match dataclass field names exactly)

**get_next_id:**
- Purpose: Monotonically increasing ID assignment
- Examples: `web.py` (lines 21-26)
- Pattern: Scans all existing ids and increments the max; deleted IDs are never reused (gaps are intentional)

**parse_tags:**
- Purpose: Normalize comma-separated tag input
- Examples: `web.py` (lines 16-18)
- Pattern: Lowercases, strips whitespace, deduplicates, sorts — returns a list of strings

## Entry Points

**Web Server:**
- Location: `web.py` (line 150: `if __name__ == "__main__":`)
- Triggers: `python web.py` (development) or gunicorn (production via Dockerfile)
- Responsibilities: Starts Flask dev server on `0.0.0.0:5000` with debug mode enabled

**`GET /`:**
- Location: `web.py` lines 29-54
- Query params: `show_done` (default `"1"`), `tag` (default `""`)
- Responsibilities: Loads all tasks, collects tag list before filtering, applies done/tag filters, sets `draggable_enabled` only when no filters are active, renders `index.html`

## Error Handling

**Strategy:** Minimal; most failures are silent redirects.

**Patterns:**
- Missing task on `GET /edit/<id>`: redirect to `/` (line 104-105)
- Empty title on `POST /add` or `POST /edit/<id>`: silently ignored, redirect to `/`
- Malformed JSON body on `POST /reorder`: returns `400 Bad request` (line 138)
- No HTTP error pages or user-facing error messages for most edge cases

## Cross-Cutting Concerns

**Logging:** None — no logging framework; no `print` statements for request tracing.

**Validation:** Only `title` emptiness is checked; priority values, date formats, and tag contents are not validated server-side.

**Authentication:** None — the application has no auth layer; all routes are publicly accessible.

**Proxy Awareness:** `ProxyFix` middleware applied (`web.py` line 13) to correctly resolve `X-Forwarded-For`, `X-Forwarded-Host`, and `X-Forwarded-Proto` headers when running behind a reverse proxy.

---

*Architecture analysis: 2026-03-23*
