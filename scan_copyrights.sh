#!/usr/bin/env bash
# Scan each recipe directory for copyrights with scancode.
#
# Usage (run from the directory containing the recipes, like before):
#   ./scan_copyrights.sh [OUT_DIR] [TEMPLATE]
#
# Defaults: OUT_DIR=../copyrights  TEMPLATE=../copyright_template.txt
#
# Tunables (environment variables):
#   PROCS=2            scancode parallel processes (lower = less RAM)
#   FILE_TIMEOUT=300   max seconds per file inside scancode
#   RECIPE_TIMEOUT=6h  max wall time per recipe (anything `timeout` accepts; 0 = none)
#   FORCE=1            rescan recipes that already have a result
#   EXIT_GRACE=60      kill scancode this many seconds after it reports it is done
#                      but has not exited (works around a hang at exit)
#
# Safe to re-run: finished recipes are skipped, failed ones are retried.

set -uo pipefail

OUT_DIR=${1:-../copyrights}
TEMPLATE=${2:-../copyright_template.txt}
PROCS=${PROCS:-2}
FILE_TIMEOUT=${FILE_TIMEOUT:-300}
RECIPE_TIMEOUT=${RECIPE_TIMEOUT:-6h}
FORCE=${FORCE:-0}
EXIT_GRACE=${EXIT_GRACE:-60}   # seconds to wait for scancode to exit after it finished

command -v scancode >/dev/null || { echo "scancode not in PATH (venv not active?)" >&2; exit 1; }
[[ -f $TEMPLATE ]] || { echo "template not found: $TEMPLATE" >&2; exit 1; }
mkdir -p "$OUT_DIR" || exit 1

LOG_DIR="$OUT_DIR/_logs"
mkdir -p "$LOG_DIR"
FAILED_LIST="$OUT_DIR/_failed.txt"
: > "$FAILED_LIST"

declare -A seen=()
ok=0 skipped=0 failed=0

shopt -s nullglob
for recipe in */; do
  recipe=${recipe%/}

  # name-version-revision -> name  (same as '-'.join(d.split('-')[:-2]))
  rname=${recipe%-*}; rname=${rname%-*}
  [[ $rname == "$recipe" || -z $rname ]] && rname=$recipe

  # two recipes mapping to the same name would overwrite each other
  if [[ -n ${seen[$rname]:-} ]]; then
    echo "WARNING: $recipe and ${seen[$rname]} both map to '$rname'; using '$recipe'" >&2
    rname=$recipe
  fi
  seen[$rname]=$recipe

  dest="$OUT_DIR/$rname"
  final="$dest/copyrights.txt"
  raw="$dest/copyrights.all.txt"
  log="$LOG_DIR/$rname.log"

  if [[ $FORCE != 1 && -s $final || $FORCE != 1 && -f $dest/.done ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  echo
  echo "[$(date '+%F %T')] processing $recipe -> $rname   (log: $log)"
  mkdir -p "$dest"
  rm -f "$dest/.done" "$raw"   # drop partial output from an earlier failed run

  tcmd=()
  [[ $RECIPE_TIMEOUT != 0 ]] && tcmd=(timeout --kill-after=60 "$RECIPE_TIMEOUT")

  start=$SECONDS
  # own process group (setsid) so the whole scancode tree can be killed at once
  setsid "${tcmd[@]}" scancode --copyright \
      -n "$PROCS" --timeout "$FILE_TIMEOUT" \
      --custom-output "$raw" \
      --custom-template "$TEMPLATE" \
      "$recipe" > "$log" 2>&1 < /dev/null &
  pid=$!
  trap 'kill -- -"$pid" 2>/dev/null; exit 130' INT TERM

  # Watchdog: scancode sometimes hangs at interpreter exit AFTER writing its
  # results ("Removing temporary files...done." is its very last message).
  finished_at=0 hung=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 2
    if (( finished_at == 0 )) && grep -q 'Removing temporary files\.\.\.done' "$log"; then
      finished_at=$SECONDS
    fi
    if (( finished_at > 0 && SECONDS - finished_at >= EXIT_GRACE )); then
      echo "  scancode finished but did not exit; killing it"
      kill -- -"$pid" 2>/dev/null; sleep 5; kill -9 -- -"$pid" 2>/dev/null
      hung=1
      break
    fi
  done
  wait "$pid" 2>/dev/null
  rc=$?
  trap - INT TERM
  elapsed=$((SECONDS - start))
  # results were fully written before the hang, so treat it as success
  (( hung )) && grep -q 'Scanning done\.' "$log" && rc=0

  if [[ $rc -eq 0 ]]; then
    # scancode creates the output file on first write, so with no copyrights
    # found there is no file at all: that is an empty result, not a failure
    [[ -f $raw ]] || : > "$raw"
    sort -u "$raw" > "$final.tmp" && mv "$final.tmp" "$final" && rm -f "$raw"
    touch "$dest/.done"     # marks success even when no copyrights were found
    echo "  ok in ${elapsed}s, $(wc -l < "$final") unique lines"
    ok=$((ok + 1))
  else
    case $rc in
      124|137) why="timed out after $RECIPE_TIMEOUT" ;;
      *)       why="scancode exit code $rc" ;;
    esac
    echo "  FAILED ($why) after ${elapsed}s; partial output kept in $raw, see $log" >&2
    echo "$recipe	$why" >> "$FAILED_LIST"
    failed=$((failed + 1))
  fi
done

echo
echo "done: $ok ok, $skipped skipped (already done), $failed failed"
[[ $failed -gt 0 ]] && echo "failed recipes listed in $FAILED_LIST"
exit $(( failed > 0 ))
