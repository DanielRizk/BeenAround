# Small Python image for the API container
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app /app/app

# Security: run as non-root + prepare writable /data
RUN useradd -m appuser \
    && chown -R appuser:appuser /app \
    && mkdir -p /data/storage \
    && chown -R appuser:appuser /data
USER appuser

EXPOSE 8080

CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "app.main:app", "--bind", "0.0.0.0:8080", "--workers", "1", "--timeout", "60"]
