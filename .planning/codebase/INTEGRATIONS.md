# External Integrations

**Analysis Date:** 2026-03-24

## APIs & External Services

None. The application makes no outbound HTTP calls to external APIs.

## Data Storage

**Local flat file:**
- Format: JSON
- Path: `tasks.json` (resolved relative to `storage.py` via `os.path.abspath`)
- Access: plain `json.load` / `json.dump` on every read/write in `storage.py`
- No connection pooling, no ORM, no migrations

**File Storage:** Local filesystem only

**Caching:** None

## Authentication & Identity

None. No login, no sessions, no auth middleware.

## Monitoring & Observability

- **Error Tracking:** None
- **Logs:** gunicorn access log to stdout (`--access-logfile -`); no structured logging in app code

## CI/CD

| Workflow | File | Trigger |
|----------|------|---------|
| Tests | `.github/workflows/test.yml` | Pull request (opened/sync/reopened) |
| Claude Code | `.github/workflows/claude.yml` | Issues / PR comments mentioning `@claude` |
| Hello World | `.github/workflows/main.yml` | Push (demo only) |

**CI secrets required:**
- `CLAUDE_CODE_OAUTH_TOKEN` — used by `anthropics/claude-code-action@v1` in `claude.yml`

**Hosting:** Not specified (Docker image is self-hosted)

## Webhooks & Callbacks

- **Incoming:** None
- **Outgoing:** None

---

*Integration audit: 2026-03-24*
