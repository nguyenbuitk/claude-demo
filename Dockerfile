# Stage 1: Builder — install dependencies into a virtualenv
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime — lean image with only the app and its dependencies
FROM python:3.12-slim

# Use the venv from builder, disable .pyc files, enable unbuffered output
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy virtualenv from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy only the files the application needs (no COPY . .)
COPY tasks.py storage.py web.py ./
COPY templates/ templates/

# Create non-root user and set ownership
RUN adduser --disabled-password --gecos "" appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

# Healthcheck using Python stdlib (no curl/wget in slim image)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Run with Gunicorn (4 workers)
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "web:app"]
