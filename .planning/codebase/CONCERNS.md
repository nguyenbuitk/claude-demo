# Codebase Concerns

**Analysis Date:** 2026-03-24

## Tech Debt

**No service layer:**
- `web.py` calls `load_tasks()` / `save_tasks()` directly in every route
- Files: `web.py` (lines 62–74, 80–85, 92–95, 101–114, 139–146)
- Impact: business logic is coupled to HTTP layer; hard to reuse or test routes in isolation

**Full file read/write on every operation:**
- Files: `storage.py` (lines 10–40)
- Impact: performance degrades linearly with task count; risk of data loss on concurrent writes (no locking)

**Priority field is unvalidated string:**
- Files: `tasks.py` (line 13), `web.py` (lines 69, 111)
- Impact: any string accepted from form input; invalid values silently persist to JSON

**No input validation on `due_date`:**
- Files: `web.py` (lines 63, 112)
- Impact: malformed date strings accepted and stored; no format enforcement

## Security Considerations

**Debug mode enabled in production entrypoint:**
- Files: `web.py` (line 151): `app.run(debug=True, ...)`
- Risk: Werkzeug debugger PIN exposed if served directly; must be disabled behind gunicorn/uwsgi
- Current mitigation: Dockerfile likely uses a proper server, but the `if __name__ == "__main__"` path is dangerous

**`client_ip` / `client_host` passed to template but ProxyFix trust is broad:**
- Files: `web.py` (lines 13, 42–43)
- Risk: `x_for=1` trusts one proxy hop; spoofable if not behind a controlled proxy

**No CSRF protection on state-mutating POST routes:**
- Files: `web.py` (routes `/add`, `/done/<id>`, `/delete/<id>`, `/edit/<id>`, `/reorder`)
- Risk: cross-site requests can mutate or delete tasks without user intent

## Fragile Areas

**`tasks.json` committed to repo:**
- Files: `tasks.json`
- Why fragile: production data mixed with source code; conflicts on git pull

**`reorder` endpoint trusts client-supplied ID list without authentication:**
- Files: `web.py` (lines 133–147)
- Risk: any client can arbitrarily reorder (or effectively drop) tasks by sending a crafted JSON payload

**`get_next_id` is not atomic:**
- Files: `web.py` (lines 21–26)
- Risk: concurrent requests can assign duplicate IDs (no DB sequence or lock)

## Test Coverage Gaps

**No tests for `storage.py`:**
- What's not tested: `load_tasks`, `save_tasks`, file-not-found path, corrupt JSON
- Files: `tests/test_tasks.py` — only covers `Task` dataclass
- Priority: High

**No tests for any Flask routes:**
- What's not tested: `add`, `done`, `delete`, `edit`, `reorder`, filtering logic
- Files: `web.py` — zero route coverage
- Priority: High

**No tests for `parse_tags` or `get_next_id`:**
- Files: `web.py` (lines 16–26)
- Priority: Medium

---

*Concerns audit: 2026-03-24*
