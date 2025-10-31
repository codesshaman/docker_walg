#!/bin/bash

set -e

# Get db volume path and container name from environment file
full_path="$(grep "DB_VOLUME" .env | sed -r 's/.*=//')"
postgres_path="$(dirname "$full_path")"
cont_name="$(grep "POSTGRES_SERVICE_NAME" .env | sed -r 's/.*=//')"
pgdata="/var/lib/postgresql/data"
BACKUP_TIME="${2}"
backup="${1}"

# # Get postgres path from db volume path

echo "$postgres_path"
echo "$cont_name"
echo "$backup_time"
echo "$backup"

# # Shutdown postgresql container
cd "$postgres_path" && docker compose down "$cont_name" && cd -

# Remove old data
COMMAND="rm -rf /var/lib/postgresql/data/*"
# Apply command
docker-compose -f ./docker-compose.yml run --rm --entrypoint bash wal-g-restore -c "${COMMAND}"

# Create recovery signal file
COMMAND="touch /var/lib/postgresql/data/recovery.signal"
# Apply command
docker-compose -f ./docker-compose.yml run --rm --entrypoint bash  wal-g-restore -c "${COMMAND}"

# Restore data from backup
COMMAND="backup-fetch /var/lib/postgresql/data $backup"
# Apply command
docker-compose -f ./docker-compose.yml run --rm wal-g-restore "${COMMAND}"

# Add recovery parameters to postgresql.conf file
# BACKUP_TIME="$backup_time" docker-compose -f ./docker-compose.yml up -d wal-g-conf
docker-compose -f docker-compose.yml run -e BACKUP_TIME="$backup_time" wal-g-conf
# docker exec --user postgres $cont_name pg_ctl -D /var/lib/postgresql/data stop -m fast || true

# Start postgresql container
# cd "$postgres_path" && make start