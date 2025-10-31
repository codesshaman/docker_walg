#!/bin/bash

# Get db volume path and container name from environment file
full_path="$(grep "DB_VOLUME" .env | sed -r 's/.*=//')"

# Get postgres path from db volume path
postgres_path="$(dirname "$full_path")"

# Start postgresql container
cd "$postgres_path" && make start
