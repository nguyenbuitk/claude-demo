# Phase 1 — Dockerize

**Goal:** Flask app chạy trong Docker container, có `/health` endpoint, image nhỏ gọn dùng multi-stage build
**Branch:** `gsd/phase-01-dockerize`
**Completed:** 2026-03-24

## Progress

| Step | Resource | Status |
|------|----------|--------|
| 1 | `/health` endpoint | ✅ Done (2026-03-24) |
| 2 | Multi-stage Dockerfile | ✅ Done (2026-03-24) |
| 3 | Non-root user + HEALTHCHECK | ✅ Done (2026-03-24) |
| 4 | Gunicorn production server | ✅ Done (2026-03-24) |
| 5 | Tests (pytest) | ✅ Done (2026-03-24) |

---

## Step 1: `/health` Endpoint ✅

**Kết quả thực tế** — `web.py`:
```python
@app.route("/health")
def health():
    return jsonify(status="ok", version="phase-04")
```

- Returns `{"status": "ok"}` HTTP 200
- Dùng cho Docker HEALTHCHECK và ALB Target Group health check

---

## Step 2: Multi-stage Dockerfile ✅

**Kết quả thực tế** — `Dockerfile`:

```dockerfile
# Stage 1: Builder — install dependencies into a virtualenv
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime — lean image
FROM python:3.12-slim
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY tasks.py storage.py web.py ./
COPY templates/ templates/
```

**Lý do multi-stage:**
- Stage 1 (builder): cài pip packages → venv
- Stage 2 (runtime): chỉ copy venv, không có pip/build tools → image nhỏ hơn

---

## Step 3: Non-root User + HEALTHCHECK ✅

**Kết quả thực tế:**

```dockerfile
RUN adduser --disabled-password --gecos "" appuser \
    && chown -R appuser:appuser /app
USER appuser

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1
```

**Lưu ý quan trọng:**
- `python:3.12-slim` **không có `curl`** → dùng Python `urllib` cho HEALTHCHECK
- Nếu dùng `curl` trong ECS Task Definition health check sẽ fail (lesson learned từ Phase 4)

---

## Step 4: Gunicorn Production Server ✅

**Kết quả thực tế:**

```dockerfile
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "web:app"]
```

- 4 workers (phù hợp với 0.25–1 vCPU)
- Bind `0.0.0.0` để nhận traffic từ ALB/Docker
- `--access-logfile -` → logs ra stdout (CloudWatch nhận được)

---

## Step 5: Tests (pytest) ✅

**Files:**
- `tests/test_tasks.py` — 4 tests: Task dataclass, priority, complete(), __str__()
- `tests/test_web.py` — 4 tests: /health status 200, content-type JSON, body `status=ok`, GET / works

**Lưu ý:**
- `test_health_body` dùng `data["status"] == "ok"` thay vì exact match `== {"status": "ok"}`
  → Cho phép thêm fields như `version` mà không break test

---

## Key Files

| File | Mô tả |
|------|-------|
| `Dockerfile` | Multi-stage build, non-root user, Python healthcheck |
| `web.py` | Flask app, `/health` endpoint |
| `requirements.txt` | Flask, Werkzeug, Jinja2, gunicorn, psycopg2-binary |
| `tasks.py` | Task dataclass |
| `storage.py` | Dual-mode storage (JSON / PostgreSQL) |
| `tests/test_web.py` | 4 web tests |
| `tests/test_tasks.py` | 4 task model tests |

---

## Verify Checklist

- [x] `docker build -t claude-demo .` thành công
- [x] `docker run -p 5000:5000 claude-demo` → app chạy
- [x] `curl http://localhost:5000/health` → `{"status": "ok"}` HTTP 200
- [x] `pytest` → 8/8 pass
- [x] Container chạy bằng user `appuser` (không phải root)
