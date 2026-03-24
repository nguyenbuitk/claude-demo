# Technology Stack

**Analysis Date:** 2026-03-24

## Languages

- Python 3.12 — all application code (`tasks.py`, `storage.py`, `web.py`)
- HTML/Jinja2 — templates (`templates/index.html`)

## Runtime

- **Environment:** CPython 3.12 (pinned in `Dockerfile`)
- **Package Manager:** pip
- **Lockfile:** None — `requirements.txt` pins exact versions

## Frameworks

| Framework | Version | Purpose |
|-----------|---------|---------|
| Flask | 3.1.3 | Web framework, routing, templates |
| Werkzeug | 3.1.6 | WSGI utilities, `ProxyFix` middleware |
| Jinja2 | 3.1.2 | HTML templating (bundled with Flask) |
| gunicorn | 23.0.0 | Production WSGI server (4 workers) |

**Testing:**
- pytest — test runner (installed separately, not in `requirements.txt`)

## Key Dependencies

- `werkzeug.middleware.proxy_fix.ProxyFix` — used in `web.py` for reverse-proxy header forwarding
- Python stdlib only: `dataclasses`, `datetime`, `json`, `os`, `typing`

## Configuration

- No environment variable configuration for app behaviour
- `PYTHONUNBUFFERED=1` set in `docker-compose.yml`
- Data file path resolved at module load in `storage.py` via `os.path.abspath(__file__)`

## Build / Deployment

| Artifact | Detail |
|----------|--------|
| `Dockerfile` | `python:3.12-slim`, non-root `appuser`, exposes port 5000 |
| `docker-compose.yml` | Single `app` service, binds `127.0.0.1:5000`, mounts `tasks.json` volume |
| Dev server | `python web.py` (Flask debug mode, port 5000) |
| Prod server | `gunicorn --workers 4 --bind 0.0.0.0:5000 web:app` |

---

*Stack analysis: 2026-03-24*
