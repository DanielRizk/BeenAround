#!/usr/bin/env bash
set -e

export POSTGRES_PORT="${POSTGRES_PORT:-5432}"

echo "Waiting for Postgres on 127.0.0.1:${POSTGRES_PORT}..."
for i in {1..60}; do
  if pg_isready -h 127.0.0.1 -p "${POSTGRES_PORT}" >/dev/null 2>&1; then
    echo "Postgres is ready."
    exec /opt/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8080
  fi
  sleep 1
done

echo "Postgres did not become ready in time."
exit 1
