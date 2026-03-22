FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install dependencies first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user for security
RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Run with Gunicorn (4 workers)
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "--access-logfile", "-", "web:app"]
