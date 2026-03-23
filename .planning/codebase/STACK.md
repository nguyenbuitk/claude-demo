# Technology Stack

**Analysis Date:** 2026-03-23

## Languages

**Primary:**
- Python 3.12 - All application code (web app, data model, storage, tests)

**Secondary:**
- HTML/Jinja2 - Server-side templating at `templates/index.html`

## Runtime

**Environment:**
- Python 3.12 (confirmed via system `python3 --version`)

**Package Manager:**
- pip - dependencies declared in `requirements.txt`
- Lockfile: Not present (no `requirements.lock` or `pip.lock`)

## Frameworks

**Core:**
- Flask 3.1.3 - Web framework; handles routing, request/response, templating
- Werkzeug 3.1.6 - WSGI utilities; `ProxyFix` middleware used in `web.py`
- Jinja2 3.1.2 - Templating engine (bundled with Flask, pinned explicitly)

**Testing:**
- pytest - Test runner (not pinned in `requirements.txt`; invoked via `pytest` command)

**Production Server:**
- Gunicorn 23.0.0 - WSGI server; runs 4 workers bound to `0.0.0.0:5000`

**Build/Dev:**
- No build tools (pure Python, no transpilation or asset pipeline)

## Key Dependencies

**Critical:**
- `Flask==3.1.3` (`requirements.txt`) - Core web framework; all routes defined in `web.py`
- `Werkzeug==3.1.6` (`requirements.txt`) - WSGI layer; `ProxyFix` used to handle reverse proxy headers
- `Jinja2==3.1.2` (`requirements.txt`) - Template rendering; single shared template `templates/index.html`
- `gunicorn==23.0.0` (`requirements.txt`) - Production WSGI server; referenced in `Dockerfile` CMD

**Infrastructure:**
- Docker - Container image defined in `Dockerfile`; compose config in `docker-compose.yml`

## Configuration

**Environment:**
- `PYTHONUNBUFFERED=1` set in `docker-compose.yml` for real-time log output
- No application secrets or API keys required
- `.env` and `.env.*` files are gitignored (none currently present)

**Build:**
- `Dockerfile` - Multi-stage Python 3.12-slim image; non-root `appuser`; runs Gunicorn
- `docker-compose.yml` - Single `app` service; port `127.0.0.1:5000:5000`; bind-mounts `tasks.json` for data persistence

## Platform Requirements

**Development:**
- Python 3.12+
- pip
- Run: `python web.py` (Flask dev server, port 5000, debug mode)
- Tests: `pytest`

**Production:**
- Docker (compose v2 compatible)
- Image based on `python:3.12-slim`
- Gunicorn serves on port 5000 with 4 workers
- `tasks.json` must be writable and bind-mounted for data persistence

---

*Stack analysis: 2026-03-23*
