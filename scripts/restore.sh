#!/bin/bash

set -e

# Get db volume path and container name from environment file
full_path="$(grep "DB_VOLUME" .env | sed -r 's/.*=//')"
cont_name="$(grep "POSTGRES_SERVICE_NAME" .env | sed -r 's/.*=//')"

# # Get postgres path from db volume path
# postgres_path="$(dirname "$full_path")"

# echo "$postgres_path"
# echo "$cont_name"

# # Shutdown postgresql container
# cd "$postgres_path" && docker compose down "$cont_name"

PGDATA="/var/lib/postgresql/data"
BACKUP_TIME="${1:-LATEST}"

touch /var/lib/postgresql/data/recovery.signal

cat > /var/lib/postgresql/data/postgresql.conf << 'EOF'
restore_command = 'wal-g wal-fetch "%f" "%p"'
recovery_target_timeline = 'latest'
recovery_target_time = ${BACKUP_TIME}
EOF

docker exec --user postgres $cont_name pg_ctl -D /var/lib/postgresql/data stop -m fast || true

docker exec --user postgres $cont_name pg_ctl -D /var/lib/postgresql/data status

docker exec --user postgres $cont_name pg_ctl -D /var/lib/postgresql/data status