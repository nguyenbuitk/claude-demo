# Phase 1: Dockerize - Research

**Researched:** 2026-03-24
**Domain:** Docker containerization for a Python Flask application
**Confidence:** HIGH

## Summary

Phase 1 containerizes the existing Flask task-management app. The codebase already has a working Dockerfile, .dockerignore, and docker-compose.yml -- but they do not fully satisfy the requirements. Specifically: (1) the Dockerfile is a single-stage build, not multi-stage as DOC-01 requires, (2) there is no `/health` endpoint in web.py (DOC-02), and (3) there is no `HEALTHCHECK` instruction in the Dockerfile (DOC-03). The docker-compose.yml has a healthcheck, but it targets `GET /` (not `/health`) and uses `curl` which is not installed in `python:3.12-slim`.

The work is straightforward: add a `/health` route to `web.py`, convert the Dockerfile to multi-stage, add a `HEALTHCHECK` instruction, and update `.dockerignore` if needed. No new libraries are required. The existing `requirements.txt` already pins Flask 3.1.3, Werkzeug 3.1.6, Jinja2 3.1.2, and gunicorn 23.0.0.

**Primary recommendation:** Upgrade the existing Dockerfile to multi-stage with HEALTHCHECK, add `/health` to web.py, and verify with `docker build` + `docker run` + `curl /health`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Dockerfile at repo root -- multi-stage build, non-root user | Existing Dockerfile has non-root user but is single-stage. Convert to multi-stage (builder + runtime). Pattern documented below. |
| DOC-02 | `/health` endpoint returns 200 JSON `{"status": "ok"}` | No `/health` route exists in web.py. Add a simple Flask route returning `jsonify({"status": "ok"})`. |
| DOC-03 | `HEALTHCHECK` instruction in Dockerfile | Not present. Add `HEALTHCHECK` using Python urllib (no curl/wget in slim image). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Test runner:** `pytest` (run all: `pytest`, single: `pytest tests/test_tasks.py::test_task_creation`)
- **Web app:** `python web.py` runs Flask on port 5000
- **Architecture:** web.py calls storage.py directly (no service layer). storage.py reads/writes `tasks.json` relative to its own module path.
- **Data file:** `tasks.json` is in .gitignore -- it is runtime data, not committed.

## Standard Stack

### Core (already in requirements.txt)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flask | 3.1.3 | Web framework | Already the app framework |
| gunicorn | 23.0.0 | WSGI production server | Already in requirements.txt, used in existing Dockerfile CMD |
| Werkzeug | 3.1.6 | WSGI utilities (Flask dependency) | Already pinned |
| Jinja2 | 3.1.2 | Template engine (Flask dependency) | Already pinned |

### Docker Base Images

| Image | Purpose | Why |
|-------|---------|-----|
| `python:3.12-slim` (builder stage) | Install/compile dependencies | Matches project's Python version; slim avoids unnecessary bulk |
| `python:3.12-slim` (runtime stage) | Run the app | Same base for compatibility; slim keeps image small (~150MB) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `python:3.12-slim` for both stages | `python:3.12-alpine` | Alpine uses musl libc which can cause subtle issues with some Python packages; slim is Debian-based and more predictable |
| Python urllib for healthcheck | Install curl via apt-get | Adds ~10MB and an extra apt layer; Python is already available |
| gunicorn | uvicorn | gunicorn is already in requirements.txt and Dockerfile; no reason to change for a sync Flask app |

**No new packages required.** The existing `requirements.txt` is sufficient.

## Architecture Patterns

### Existing File Layout (relevant files)

```
claude-demo/
  Dockerfile           # EXISTS -- needs multi-stage conversion + HEALTHCHECK
  .dockerignore        # EXISTS -- already excludes .git, __pycache__, tests, etc.
  docker-compose.yml   # EXISTS -- healthcheck targets wrong endpoint, uses curl
  requirements.txt     # EXISTS -- Flask, Werkzeug, Jinja2, gunicorn
  web.py               # EXISTS -- needs /health endpoint added
  tasks.py             # No changes needed
  storage.py           # No changes needed (tasks.json path is module-relative)
  templates/           # No changes needed
```

### Pattern 1: Multi-Stage Dockerfile for Python

**What:** Two stages -- a `builder` that installs dependencies into a virtualenv, and a `runtime` that copies only the virtualenv and app code.

**When to use:** Always for production Python images. Separates build tools (pip, setuptools, wheel) from the final image.

**Example:**

```dockerfile
# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

# Environment: use the venv, no .pyc files, unbuffered output
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy venv from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY tasks.py storage.py web.py ./
COPY templates/ templates/

# Non-root user
RUN adduser --disabled-password --gecos "" appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

# Healthcheck using Python (no curl/wget in slim image)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "web:app"]
```

**Source:** Synthesized from Docker official docs + Python multi-stage build community best practices.

### Pattern 2: Flask Health Endpoint

**What:** A simple GET route that returns JSON `{"status": "ok"}` with HTTP 200.

**When to use:** Every containerized web service needs a health endpoint for orchestrator probes.

**Example:**

```python
from flask import jsonify

@app.route("/health")
def health():
    return jsonify(status="ok")
```

**Key points:**
- Must be a GET endpoint (healthchecks use GET by default).
- Returns JSON with Content-Type `application/json`.
- No authentication (health probes come from infrastructure, not users).
- Should be fast and not depend on external state. For this app, a simple 200 is appropriate since there is no database.

### Pattern 3: .dockerignore Best Practices

The existing `.dockerignore` is solid. It excludes `.git`, `__pycache__`, `*.pyc`, `.planning`, `.playwright-mcp`, `tests`, and `.claude`. Consider also adding:
- `docker-compose.yml` (not needed inside the image)
- `*.md` (docs not needed at runtime)
- `.github/` (CI config not needed in image)
- `conftest.py` (test infrastructure)
- `test.txt` (test data)

### Anti-Patterns to Avoid

- **Using `COPY . .` in final stage:** Copies everything including test files, docs, .git remnants. Instead, copy only the files the app needs (`tasks.py`, `storage.py`, `web.py`, `templates/`).
- **Installing curl/wget just for healthcheck:** Wastes space and adds attack surface. Python's `urllib.request` is already present.
- **Running as root:** The existing Dockerfile already handles this correctly with `adduser` + `USER appuser`.
- **Putting HEALTHCHECK in docker-compose only:** DOC-03 explicitly requires `HEALTHCHECK` in the Dockerfile itself.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WSGI server | Custom threaded server | gunicorn (already in requirements) | Production-grade, handles worker management, graceful shutdown |
| Health endpoint response | Manual string concatenation | `flask.jsonify()` | Correct Content-Type header, proper JSON encoding |
| Docker healthcheck HTTP client | Install curl/wget | Python `urllib.request.urlopen` | Zero additional dependencies in python:3.12-slim |

## Common Pitfalls

### Pitfall 1: tasks.json File Permissions in Container

**What goes wrong:** The app writes to `tasks.json` using a path relative to `storage.py`'s module directory (`os.path.dirname(os.path.abspath(__file__))`). Inside Docker, this resolves to `/app/tasks.json`. If the file does not exist, `storage.py` creates it. But if the `/app` directory is owned by root and the process runs as `appuser`, the write fails with PermissionError.

**Why it happens:** The `COPY` instruction creates files owned by root. The `chown` in the Dockerfile must cover `/app` recursively.

**How to avoid:** Ensure the `RUN chown -R appuser:appuser /app` comes after all COPY instructions, before switching to `USER appuser`. The existing Dockerfile already does this correctly.

**Warning signs:** Container starts but crashes on first task creation with a `PermissionError` traceback.

### Pitfall 2: HEALTHCHECK Timing on Cold Start

**What goes wrong:** HEALTHCHECK fires before gunicorn workers are ready, marking the container as unhealthy during startup.

**Why it happens:** Default HEALTHCHECK has no start period.

**How to avoid:** Use `--start-period=10s` to give gunicorn time to boot workers before health checks begin counting.

**Warning signs:** Container cycling between healthy/unhealthy shortly after start.

### Pitfall 3: Layer Cache Invalidation

**What goes wrong:** Changing any source file invalidates the pip install layer, causing full dependency reinstall on every build.

**Why it happens:** Single `COPY . .` before `pip install`, or in a single-stage build where code copy comes before dependency copy.

**How to avoid:** In the builder stage, copy `requirements.txt` first, install, then copy app code in the runtime stage. The multi-stage pattern naturally separates these.

**Warning signs:** Builds take 30-60 seconds instead of 2-3 seconds when only code changed.

### Pitfall 4: curl Not Available in python:3.12-slim

**What goes wrong:** `HEALTHCHECK CMD curl --fail http://localhost:5000/health` fails because curl is not installed in `python:3.12-slim`.

**Why it happens:** The slim variant strips non-essential packages including curl.

**How to avoid:** Use `python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"` instead.

**Warning signs:** Container shows as "unhealthy" immediately; `docker inspect` shows healthcheck exit code 127 (command not found).

### Pitfall 5: Existing docker-compose.yml Healthcheck Conflict

**What goes wrong:** The existing `docker-compose.yml` has a healthcheck that targets `GET /` with `curl`. After adding HEALTHCHECK to the Dockerfile, the compose healthcheck overrides it.

**Why it happens:** docker-compose healthcheck takes precedence over Dockerfile HEALTHCHECK.

**How to avoid:** Update the docker-compose.yml healthcheck to also target `/health` and use a command that works (Python urllib or install curl). Alternatively, remove the compose healthcheck and let the Dockerfile one take effect. This is a nice-to-have cleanup but not strictly required by the phase requirements.

**Warning signs:** `docker compose up` shows unhealthy even though `docker run` shows healthy.

## Code Examples

### Health Endpoint (add to web.py)

```python
from flask import jsonify

@app.route("/health")
def health():
    return jsonify(status="ok")
```

### HEALTHCHECK in Dockerfile (using Python stdlib)

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1
```

### Verification Commands

```bash
# Build
docker build -t claude-demo .

# Run
docker run -d -p 5000:5000 --name claude-demo-test claude-demo

# Wait for startup, then check health endpoint
sleep 5
curl -s http://localhost:5000/health
# Expected: {"status":"ok"}

# Check container health status
docker inspect --format='{{.State.Health.Status}}' claude-demo-test
# Expected: healthy (after start-period + one interval)

# Cleanup
docker stop claude-demo-test && docker rm claude-demo-test
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-stage Dockerfile | Multi-stage builds | Docker 17.05+ (2017) | 50-80% smaller images, better security |
| curl in HEALTHCHECK | Python urllib for Python images | Common since slim images became default (~2020) | No extra apt packages needed |
| `pip install` globally | virtualenv in multi-stage | Best practice since ~2022 | Cleaner dependency isolation, smaller runtime image |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Build and run container | Yes | 29.3.0 | -- |
| Python 3.12 | App runtime (in container) | Yes (host: 3.12.3) | 3.12.3 | -- |
| pytest | Test /health endpoint | Yes | 9.0.2 | -- |
| curl | Manual verification of /health | Yes | 8.5.0 | -- |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Existing State Analysis (Gap Assessment)

What exists vs. what requirements demand:

| Requirement | Current State | Gap | Action |
|-------------|--------------|-----|--------|
| DOC-01: Multi-stage Dockerfile with non-root user | Single-stage Dockerfile with non-root user | Missing multi-stage | Rewrite Dockerfile with builder + runtime stages |
| DOC-02: `/health` returns `{"status": "ok"}` | No `/health` route in web.py | Missing entirely | Add `health()` route to web.py |
| DOC-03: `HEALTHCHECK` in Dockerfile | No HEALTHCHECK instruction | Missing entirely | Add HEALTHCHECK using Python urllib |

**Bonus cleanup (not required but recommended):**
- Update `.dockerignore` to also exclude `docker-compose.yml`, `*.md`, `.github/`, `conftest.py`, `test.txt`
- Update `docker-compose.yml` healthcheck to target `/health` (currently targets `/` with curl which does not exist in slim image)

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | pytest 9.0.2 |
| Config file | None (conftest.py at root provides sys.path only) |
| Quick run command | `pytest -x` |
| Full suite command | `pytest` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-01 | Dockerfile builds successfully with multi-stage | smoke | `docker build -t claude-demo .` | N/A (shell command, not pytest) |
| DOC-01 | Container runs as non-root user | smoke | `docker run --rm claude-demo whoami` (expect "appuser") | N/A (shell command) |
| DOC-02 | `/health` returns 200 `{"status":"ok"}` | unit | `pytest tests/test_web.py::test_health_endpoint -x` | No -- Wave 0 |
| DOC-03 | HEALTHCHECK present in Dockerfile | smoke | `docker inspect claude-demo --format='{{.Config.Healthcheck}}'` | N/A (shell command) |
| DOC-03 | Container reaches "healthy" status | integration | `docker run -d ... && sleep 15 && docker inspect --format='{{.State.Health.Status}}'` | N/A (shell command) |

### Sampling Rate

- **Per task commit:** `pytest -x` (existing tests still pass)
- **Per wave merge:** `pytest && docker build -t claude-demo .`
- **Phase gate:** Full build + run + health check verification before verify-work

### Wave 0 Gaps

- [ ] `tests/test_web.py` -- Flask test client tests for `/health` endpoint (DOC-02)
- [ ] No framework config changes needed (pytest works out of the box)

## Open Questions

1. **Whether to update docker-compose.yml in this phase**
   - What we know: The existing docker-compose.yml healthcheck uses curl (not available) and targets `/` instead of `/health`.
   - What's unclear: Phase scope says "Files touched: Dockerfile, web.py, .dockerignore" -- docker-compose.yml is not listed.
   - Recommendation: Fix docker-compose.yml as part of this phase since it directly relates to Docker health checks and will break if left as-is after curl removal. But this is a discretionary add-on -- not blocking.

2. **Number of gunicorn workers**
   - What we know: Existing Dockerfile uses `--workers 4`. For a learning/demo app this is fine.
   - What's unclear: Whether resource limits will matter in later K8s phase (Phase 3).
   - Recommendation: Keep `--workers 4` for now. Phase 3 can tune this when resource limits are defined.

## Sources

### Primary (HIGH confidence)
- Existing codebase files: `Dockerfile`, `web.py`, `storage.py`, `tasks.py`, `requirements.txt`, `.dockerignore`, `docker-compose.yml` -- direct inspection
- Docker official documentation on HEALTHCHECK: https://docs.docker.com/reference/dockerfile/#healthcheck
- Docker official documentation on multi-stage builds: https://docs.docker.com/build/building/multi-stage/

### Secondary (MEDIUM confidence)
- Multi-stage Python Dockerfile patterns: https://pythonspeed.com/articles/multi-stage-docker-python/
- Docker healthcheck without curl: https://muratcorlu.com/docker-healthcheck-without-curl-or-wget/
- Docker best practices for Python 2025: https://collabnix.com/10-essential-docker-best-practices-for-python-developers-in-2025/
- Snyk containerizing Python best practices: https://snyk.io/blog/best-practices-containerizing-python-docker/

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages already in requirements.txt, versions verified from installed packages
- Architecture: HIGH -- multi-stage Dockerfile is well-established pattern, app is simple
- Pitfalls: HIGH -- based on direct inspection of existing code (storage.py path resolution, slim image missing curl)

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain, Docker and Flask patterns change slowly)
