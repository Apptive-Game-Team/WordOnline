#!/usr/bin/env bash
#
# Brings up the throwaway PostgreSQL the capacity search runs against, applies the
# database repository's migrations to it and creates the two tables that exist on the
# deployed databases but that no migration in the repository creates (magic_tags,
# tag_counter_rules). Idempotent: run it again and it re-uses the container.
#
# Usage: setup-db.sh [--migrations DIR] [--container NAME] [--network NAME] [--port PORT]

set -euo pipefail

MIGRATIONS="${MIGRATIONS:-$HOME/dev/arcane-casters/database/migration}"
CONTAINER="${CONTAINER:-ac-loadtest-postgres}"
NETWORK="${NETWORK:-ac-loadtest}"
HOST_PORT="${HOST_PORT:-55432}"
DB_NAME=wordonline
DB_USER=loadtest
DB_PASSWORD=loadtest

while [ $# -gt 0 ]; do
    case "$1" in
        --migrations) MIGRATIONS="$2"; shift 2 ;;
        --container)  CONTAINER="$2";  shift 2 ;;
        --network)    NETWORK="$2";    shift 2 ;;
        --port)       HOST_PORT="$2";  shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

psql_run() { docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$1" -q; }

docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK" >/dev/null

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "starting $CONTAINER"
    docker run -d --name "$CONTAINER" --network "$NETWORK" \
        -e POSTGRES_USER="$DB_USER" -e POSTGRES_PASSWORD="$DB_PASSWORD" -e POSTGRES_DB="$DB_NAME" \
        -p "$HOST_PORT":5432 postgres:16 >/dev/null
elif [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" != "true" ]; then
    docker start "$CONTAINER" >/dev/null
fi

until docker exec "$CONTAINER" pg_isready -U "$DB_USER" >/dev/null 2>&1; do sleep 1; done

# The migrations name this role as the owner of everything V000 creates.
psql_run postgres <<SQL
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'wordonline') THEN
        CREATE ROLE wordonline LOGIN PASSWORD '$DB_PASSWORD';
    END IF;
END \$\$;
SQL

if docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -tAc \
        "SELECT to_regclass('public.flyway_schema_history') IS NOT NULL" | grep -q t; then
    echo "schema already present, skipping migrate"
else
    # V000 is an IDE-generated dump: alongside the real tables it re-declares parts of
    # information_schema and pg_catalog, which Flyway aborts on. psql applies it
    # statement by statement instead and the catalog statements simply fail; a second
    # pass picks up the tables whose dependencies had not been created yet on the first.
    echo "applying V000 through psql (catalog statements are expected to fail)"
    docker cp "$MIGRATIONS/V000_20260406__init_tables.sql" "$CONTAINER:/tmp/v000.sql"
    docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -q -f /tmp/v000.sql >/dev/null 2>&1 || true
    docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -q -f /tmp/v000.sql >/dev/null 2>&1 || true

    echo "baselining and migrating the rest"
    flyway() {
        docker run --rm --network "$NETWORK" -v "$MIGRATIONS":/flyway/sql:ro flyway/flyway:10 \
            -url="jdbc:postgresql://$CONTAINER:5432/$DB_NAME" -user="$DB_USER" -password="$DB_PASSWORD" \
            -mixed=true -connectRetries=10 "$@"
    }
    flyway -baselineVersion="000.20260406" -baselineDescription="init tables" baseline >/dev/null
    flyway migrate | tail -2

    # Drift: the game reads both tables, no migration in the repository creates them.
    psql_run "$DB_NAME" <<'SQL'
CREATE TABLE IF NOT EXISTS magic_tags (
    magic_id BIGINT NOT NULL REFERENCES magics(id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (magic_id, tag_id)
);
CREATE TABLE IF NOT EXISTS tag_counter_rules (
    id BIGSERIAL PRIMARY KEY,
    attacker_tag_id BIGINT NOT NULL REFERENCES tags(id),
    target_tag_id BIGINT NOT NULL REFERENCES tags(id),
    weight DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    UNIQUE (attacker_tag_id, target_tag_id)
);
SQL
fi

enabled_bots=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT count(*) FROM bot_personas WHERE enabled")
echo "ready: $CONTAINER, enabled bot personas: $enabled_bots"
[ "$enabled_bots" -ge 2 ] || { echo "need at least two enabled bot personas" >&2; exit 1; }
