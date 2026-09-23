#!/usr/bin/env bash
# romm-restore-database.sh [backup-file-name]
#
# Replaces the RomM database with one of the dumps the backups service wrote.
#
#   ./romm-restore-database.sh               list the dumps and ask
#   ./romm-restore-database.sh <file-name>   restore that one
#
# EVERY PATH AND NAME COMES FROM THE RUNNING BACKUPS CONTAINER, NOT FROM HERE.
# The previous version kept its own copy of the backup directory, and the copy
# said /srv/romm-mariadb/backups while the stack wrote to
# /srv/romm-mariadb/backups: on the day it was needed it would have listed
# nothing. The backup loop reads its directories and names from its own
# environment, so this asks that environment, and the two cannot disagree.
#
# CI runs this exact file. The end-to-end test used to restore with its own copy
# of these commands, which is how a restore script could be wrong for weeks
# while every run was green.
#
# Set COMPOSE_PROJECT_NAME if the stack was started with a -p other than romm.
set -Eeuo pipefail

PROJECT="${COMPOSE_PROJECT_NAME:-romm}"
APP_SERVICE="romm"
DB_NAME="romm"

cid() {  # the container of one compose service in this project
  docker ps -aq --filter "label=com.docker.compose.project=$PROJECT" \
    --filter "label=com.docker.compose.service=$1" | head -n 1
}
APP="$(cid "$APP_SERVICE")"; BKP="$(cid backups)"
[ -n "$BKP" ] || { echo "error: no backups container in compose project '$PROJECT' (set COMPOSE_PROJECT_NAME)" >&2; exit 1; }
[ -n "$APP" ] || { echo "error: no $APP_SERVICE container in compose project '$PROJECT'" >&2; exit 1; }
[ "$(docker inspect -f '{{.State.Running}}' "$BKP")" = true ] || { echo "error: the backups container is not running" >&2; exit 1; }

env_of() { docker exec "$BKP" printenv "$1"; }
DIR="$(env_of MARIADB_BACKUPS_PATH)"; NAME="$(env_of MARIADB_BACKUP_NAME)"
DB_USER="$(env_of ROMM_DB_USER)"; DB_PASS="$(env_of ROMM_DB_PASSWORD)"

SELECTED="${1:-}"
if [ -z "$SELECTED" ]; then
  echo "Database backups in $DIR:"
  docker exec "$BKP" sh -c "ls -1 '$DIR' | grep -E '^$NAME-.*\\.gz\$'" || { echo "  none found" >&2; exit 1; }
  read -r -p "File name to restore: " SELECTED
fi
case "$SELECTED" in ""|*/*) echo "error: give a file name from the list, not a path" >&2; exit 1 ;; esac
docker exec "$BKP" gunzip -t "$DIR/$SELECTED" \
  || { echo "error: $DIR/$SELECTED is missing or does not open; nothing was changed" >&2; exit 1; }

echo "Stopping $APP_SERVICE so nothing writes while the database is replaced"
docker stop "$APP" >/dev/null
restart() { docker start "$APP" >/dev/null && echo "Started $APP_SERVICE"; }
trap 'restart' EXIT
echo "Restoring $SELECTED"
if ! docker exec -e MYSQL_PWD="$DB_PASS" "$BKP" bash -c "set -euo pipefail
    mariadb -h mariadb -u '$DB_USER' -e 'DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\`;'
    gunzip -c '$DIR/$SELECTED' | mariadb -h mariadb -u '$DB_USER' '$DB_NAME'"; then
  echo "error: the restore failed part-way. The database may now be empty: restore another backup before using RomM." >&2
  exit 1
fi
echo "Restored $SELECTED into $DB_NAME"
