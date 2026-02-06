#!/usr/bin/env bash
set -e

export DATA_DIR="${DATA_DIR:-/data}"
export POSTGRES_DB="${POSTGRES_DB:-beenaround}"
export POSTGRES_USER="${POSTGRES_USER:-beenaround}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-beenaround_pw}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"

mkdir -p "$DATA_DIR/pgdata"
chown -R postgres:postgres "$DATA_DIR/pgdata"

# init db if empty
if [ ! -f "$DATA_DIR/pgdata/PG_VERSION" ]; then
  echo "Initializing Postgres data dir..."
  su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D $DATA_DIR/pgdata"

  # allow local connections
  echo "host all all 127.0.0.1/32 scram-sha-256" >> "$DATA_DIR/pgdata/pg_hba.conf"
  echo "listen_addresses='127.0.0.1'" >> "$DATA_DIR/pgdata/postgresql.conf"
  echo "password_encryption='scram-sha-256'" >> "$DATA_DIR/pgdata/postgresql.conf"
fi

# start postgres temporarily to create user/db if missing
echo "Starting Postgres bootstrap..."
su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D $DATA_DIR/pgdata -o \"-p $POSTGRES_PORT\" -w start"

# create user/db if needed
su - postgres -c "psql -p $POSTGRES_PORT -tc \"SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'\" | grep -q 1 || psql -p $POSTGRES_PORT -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';\""
su - postgres -c "psql -p $POSTGRES_PORT -tc \"SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DB'\" | grep -q 1 || psql -p $POSTGRES_PORT -c \"CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;\""

echo "Stopping Postgres bootstrap..."
su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D $DATA_DIR/pgdata -m fast -w stop"

# run supervisord (starts postgres + api)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
