#!/bin/bash
set -euo pipefail

# Back up a directory into an existing borg repository.
#
# Usage: ./borg_backup.sh [-r repo] [-p prefix] [-H hook] [-k] [-c] [-V] directory
#   -r repo    borg repository (default: $BORG_REPO)
#   -p prefix  archive name prefix (default: basename of directory)
#   -H hook    command to run before the backup (e.g. a db dump or snapshot
#              script); the backup is aborted if it fails
#   -k         prune old archives (7 daily, 4 weekly, 6 monthly), then compact
#   -c         check repository consistency after the backup
#   -V         with -c, also verify data (slow, reads every chunk)
#
# Passphrase: export BORG_PASSPHRASE or BORG_PASSCOMMAND, or you will be prompted.
# Archives are named <prefix>-YYYY-MM-DD_HH:MM:SS

REPO="${BORG_REPO:-}"
PREFIX=""
HOOK=""
PRUNE=0
CHECK=0
VERIFY=0

usage() { sed -n '4,15p' "$0"; }

while getopts "r:p:H:kcVh" opt; do
    case $opt in
        r) REPO="$OPTARG" ;;
        p) PREFIX="$OPTARG" ;;
        H) HOOK="$OPTARG" ;;
        k) PRUNE=1 ;;
        c) CHECK=1 ;;
        V) VERIFY=1 ;;
        *) usage; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if ! command -v borg &> /dev/null; then
    echo "Error: borg not installed."
    exit 1
fi

if [ $# -ne 1 ] || [ ! -d "$1" ]; then
    echo "Error: provide an existing directory to back up."
    usage
    exit 1
fi

if [ -z "$REPO" ]; then
    echo "Error: no repository given (use -r or set BORG_REPO)."
    exit 1
fi

if [ "$VERIFY" -eq 1 ] && [ "$CHECK" -eq 0 ]; then
    echo "Error: -V requires -c."
    exit 1
fi

SRC="$(realpath "$1")"
PREFIX="${PREFIX:-$(basename "$SRC")}"
export BORG_REPO="$REPO"

# Refuse to run twice at once for the same source (e.g. overlapping cron jobs)
LOCK="/tmp/borg_backup_$(echo "$SRC" | tr '/' '_').lock"
exec 9> "$LOCK"
if ! flock -n 9; then
    echo "Error: another backup of $SRC is already running."
    exit 1
fi

if [ -n "$HOOK" ]; then
    echo "Running pre-backup hook: $HOOK"
    bash -c "$HOOK"
fi

echo "Backing up $SRC to $REPO as ${PREFIX}-<now>"

# exit code 1 is a warning (e.g. a file changed while being read): keep going
# but report it at the end; 2+ is a real error and aborts via set -e
rc=0
borg create \
    --verbose --stats --progress \
    --compression zstd \
    --exclude-caches \
    "::${PREFIX}-{now:%Y-%m-%d_%H:%M:%S}" \
    "$SRC" || rc=$?
if [ "$rc" -gt 1 ]; then
    echo "Error: borg create failed (exit $rc)."
    exit "$rc"
fi

if [ "$PRUNE" -eq 1 ]; then
    echo "Pruning old archives with prefix ${PREFIX}-"
    borg prune \
        --verbose --list \
        --glob-archives "${PREFIX}-*" \
        --keep-daily 7 --keep-weekly 4 --keep-monthly 6
    echo "Compacting repository to free space"
    borg compact
fi

if [ "$CHECK" -eq 1 ]; then
    if [ "$VERIFY" -eq 1 ]; then
        echo "Checking repository and verifying data (slow)"
        borg check --verbose --verify-data
    else
        echo "Checking repository"
        borg check --verbose
    fi
fi

if [ "$rc" -eq 1 ]; then
    echo "Done, but borg reported warnings (see above)."
    exit 1
fi
echo "Done."
