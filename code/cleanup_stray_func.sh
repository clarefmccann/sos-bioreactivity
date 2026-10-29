#!/usr/bin/env bash
# Remove the accidentally-created sub-<ID>/func/ folders (missing the
# ses-wavesos level) left over from the first SOS events.tsv transfer to
# Talapas. Run this ON Talapas, not locally.
#
# SAFETY:
# - Defaults to a dry run. Nothing is deleted unless you pass --execute.
# - Only looks at sub-<ID>/func (no ses- level) for the exact 75 participant
#   IDs this transfer touched -- it will not go near any other subject or
#   any sub-<ID>/ses-*/func directory.
# - For each candidate folder, it lists the contents and only queues it for
#   deletion if EVERY file in it matches the accidental events.tsv naming
#   pattern (sub-<ID>_task-sos_events.tsv). If a folder contains anything
#   else -- a real scan, a different file, whatever -- it is skipped and
#   printed as "SKIPPED (unexpected contents)" so you can look at it by hand.
#
# Usage:
#   ./cleanup_stray_func.sh /path/to/bids_root            # dry run (default)
#   ./cleanup_stray_func.sh /path/to/bids_root --execute   # actually delete

set -euo pipefail

BIDS_ROOT="${1:-}"
MODE="${2:-}"

if [ -z "$BIDS_ROOT" ]; then
  echo "Usage: $0 /path/to/bids_root [--execute]" >&2
  exit 1
fi

if [ ! -d "$BIDS_ROOT" ]; then
  echo "ERROR: $BIDS_ROOT does not exist or is not a directory." >&2
  exit 1
fi

DRY_RUN=true
if [ "$MODE" = "--execute" ]; then
  DRY_RUN=false
fi

IDS="TAG002 TAG007 TAG017 TAG019 TAG020 TAG024 TAG030 TAG032 TAG034 TAG038 TAG040 TAG041 TAG045 TAG046 TAG047 TAG048 TAG050 TAG053 TAG057 TAG059 TAG060 TAG062 TAG068 TAG074 TAG076 TAG077 TAG080 TAG081 TAG084 TAG085 TAG086 TAG087 TAG089 TAG101 TAG103 TAG106 TAG110 TAG120 TAG122 TAG131 TAG132 TAG138 TAG140 TAG141 TAG164 TAG167 TAG176 TAG179 TAG180 TAG186 TAG188 TAG200 TAG202 TAG203 TAG205 TAG207 TAG210 TAG220 TAG223 TAG224 TAG225 TAG238 TAG301 TAG303 TAG304 TAG305 TAG306 TAG307 TAG309 TAG311 TAG312 TAG313 TAG314 TAG316 TAG317"

if $DRY_RUN; then
  echo "=== DRY RUN -- nothing will be deleted. Pass --execute to actually delete. ==="
fi
echo ""

n_found=0
n_queued=0
n_skipped=0

for id in $IDS; do
  func_dir="$BIDS_ROOT/sub-${id}/func"
  if [ ! -d "$func_dir" ]; then
    continue
  fi
  n_found=$((n_found + 1))

  expected_file="sub-${id}_task-sos_events.tsv"
  contents=$(find "$func_dir" -mindepth 1)
  unexpected=false
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    base=$(basename "$item")
    if [ "$base" != "$expected_file" ]; then
      unexpected=true
    fi
  done <<< "$contents"

  if $unexpected; then
    echo "SKIPPED (unexpected contents): $func_dir"
    echo "$contents" | sed 's/^/    /'
    n_skipped=$((n_skipped + 1))
    continue
  fi

  echo "QUEUED FOR DELETION: $func_dir"
  echo "$contents" | sed 's/^/    /'
  n_queued=$((n_queued + 1))

  if ! $DRY_RUN; then
    rm -rf -- "$func_dir"
    echo "    -> deleted"
  fi
done

echo ""
echo "=== Summary ==="
n_ids=$(echo "$IDS" | wc -w | tr -d ' ')
echo "sub-<ID>/func folders found (of $n_ids candidate IDs): $n_found"
echo "Queued for deletion (contents matched expected pattern exactly): $n_queued"
echo "Skipped (unexpected contents -- review manually): $n_skipped"
if $DRY_RUN; then
  echo ""
  echo "This was a dry run. Re-run with --execute to actually delete the $n_queued queued folder(s)."
fi
