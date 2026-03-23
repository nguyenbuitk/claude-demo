# External Integrations

**Analysis Date:** 2026-03-23

## APIs & External Services

No third-party APIs or external HTTP services are called by the application. All data operations are local.

## Data Storage

**Databases:**
- None. No relational or NoSQL database is used.

**File Storage:**
- Local filesystem only. Tasks are persisted to `tasks.json` in the project root directory.
  - Read/write path resolved in `storage.py` via `os.path.abspath(__file__)`
  - In Docker, `tasks.json` is bind-mounted via `docker-compose.yml` volume: `./tasks.json:/app/tasks.json`
  - JSON is read and written in full on every operation (no incremental updates)

**Caching:**
- None.

## Authentication & Identity

**Auth Provider:**
- None. The application has no authentication or session management.

## Monitoring & Observability

**Error Tracking:**
- None. No Sentry, Rollbar, or equivalent configured.

**Logs:**
- Gunicorn access logs written to stdout (`--access-logfile -` in `Dockerfile` CMD)
- `PYTHONUNBUFFERED=1` ensures unbuffered log output in the container
- A Playwright MCP browser console log file exists at `.playwright-mcp/console-2026-03-21T13-10-32-970Z.log` (one 404 entry for `/favicon.ico`; indicates prior manual browser testing)

## CI/CD & Deployment

**Hosting:**
- Docker (self-hosted). No cloud provider detected (no AWS, GCP, Azure, Fly.io, Heroku, etc.).

**CI Pipeline - GitHub Actions (`.github/workflows/`):**

| Workflow file | Trigger | Purpose |
|---|---|---|
| `hello.yml` | `push` | Echo "Hello, GitHub Actions!" — smoke test |
| `main.yml` | `push` | Echo "Hello from GitHub Actions!" with `uname -a` — smoke test |
| `claude.yml` | Issue/PR comments containing `@claude`, issue open/assign | Runs `anthropics/claude-code-action@v1` to let Claude respond to GitHub events |
| `claude-code-review.yml` | PR opened, synchronized, ready_for_review, reopened | Runs `anthropics/claude-code-action@v1` with the `code-review` plugin for automated PR review |

**Required GitHub Secrets:**
- `CLAUDE_CODE_OAUTH_TOKEN` - Used by both `claude.yml` and `claude-code-review.yml` to authenticate with Anthropic's Claude Code Action

## Webhooks & Callbacks

**Incoming:**
- GitHub Actions webhooks trigger the Claude Code workflows (handled by GitHub infrastructure, not by the app itself)

**Outgoing:**
- None from the Flask application.

## Reverse Proxy

- `werkzeug.middleware.proxy_fix.ProxyFix` is applied in `web.py` (`x_for=1, x_host=1, x_proto=1`)
- This signals the app expects to run behind a reverse proxy (e.g., nginx) that sets `X-Forwarded-For`, `X-Forwarded-Host`, and `X-Forwarded-Proto` headers
- No reverse proxy config file is present in the repository

## Environment Configuration

**Required env vars:**
- `PYTHONUNBUFFERED=1` (set in `docker-compose.yml`; optional for dev)

**Secrets location:**
- `CLAUDE_CODE_OAUTH_TOKEN` stored as a GitHub repository secret (not in codebase)
- `.env` and `.env.*` are gitignored; no `.env` file currently present

---

*Integration audit: 2026-03-23*
