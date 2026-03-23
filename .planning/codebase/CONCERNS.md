# Codebase Concerns

**Analysis Date:** 2026-03-23

## Architecture / Tech Debt

- **No service layer** — All business logic lives directly in Flask route handlers. Routes call `load_tasks()`/`save_tasks()` directly with no intermediate abstraction. Adding complex business rules will require touching routes.
- **Flat JSON file as database** — `tasks.json` is the only persistence mechanism. Full read/write on every request; no indexing, no querying, no transactions.
- **No input validation on `priority`** — Any string is accepted as a priority value. Invalid values silently persist without error.
- **Task completion is one-way** — `complete()` sets `done = True` with no undo/reopen path. The UI has no way to reopen a completed task.
- **No pagination** — All tasks are loaded and rendered on every request. Performance degrades with large task lists.

## Security

- **No authentication or authorization** — Any user with network access can view, add, edit, complete, and delete all tasks. No login, sessions, or access control.
- **No CSRF protection** — All mutating forms (`/add`, `/done`, `/delete`, `/edit`, `/reorder`) are vulnerable to cross-site request forgery. Flask-WTF or manual CSRF tokens are absent.
- **Client IP/hostname exposed in UI** — `web.py` passes `client_ip` and `client_host` to the template. If rendered, this leaks server-side network information to the browser.
- **`debug=True` in direct-run entry point** — `if __name__ == "__main__": app.run(debug=True, ...)`. If accidentally used in production, the Werkzeug debugger exposes an interactive Python shell.
- **No input length limits** — `title`, `description`, `tags` have no maximum length. Large inputs are stored and rendered without truncation.

## Concurrency / Race Conditions

- **No file locking on `tasks.json`** — `docker-compose.yml` runs Gunicorn with 4 workers. Concurrent requests can read stale data and overwrite each other's writes (last-write-wins with no conflict detection).
- **`/reorder` silently swallows fetch errors** — The browser-side drag-and-drop handler does not surface network or server errors to the user.

## Docker / Deployment

- **`tasks.json` volume mount requires pre-existing file** — `docker-compose.yml` mounts `./tasks.json:/app/tasks.json`. If the file does not exist on the host, Docker creates a directory at that path instead, causing a startup crash.
- **Pinned direct dependencies only** — `requirements.txt` pins 4 direct dependencies but transitive dependencies are unpinned. Builds are not fully reproducible.

## Test Coverage

- **Zero tests for `storage.py`** — No coverage of the persistence layer including file I/O, deserialization, and error handling.
- **Zero tests for Flask routes** — No HTTP-level tests for any route, filter, redirect, or JSON endpoint.
- **No CI job runs pytest** — The GitHub Actions workflows exist but none execute the test suite. Test failures would not block merges.

## Missing Features

- No way to reopen/un-complete a task
- No search by title or description
- No input validation feedback (silent ignores on empty title)
- No error pages (404/500)
- No pagination or virtual scrolling for large lists

## Scalability Limits

- Single-file JSON store degrades noticeably beyond a few hundred tasks
- Full file rewrite on every mutation — no partial updates
- Cannot support horizontal scaling without shared storage or a real database
