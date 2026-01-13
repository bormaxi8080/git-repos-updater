#!/bin/bash
# https://github.com/bormaxi8080/git-repos-updater.git

# Safety / behavior:
# - Exit on errors in general, but keep going per-repo (we catch failures).
# - Robust handling of spaces/newlines in paths (NUL-delimited find).
set -Eeuo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 [DESTINATION PATH]"
  exit 1
fi

DESTINATION_PATH="$1"

if [ ! -d "$DESTINATION_PATH" ]; then
  echo "error: DESTINATION PATH does not exist or is not a directory: $DESTINATION_PATH"
  exit 1
fi

echo "This is script for reset --hard HEAD update all git local repositories placed in specified folder"
echo "DESTINATION PATH: $DESTINATION_PATH"
echo "---------------------------------------------------"
echo ""

# GitHub / Git transport options (as in original script)
# https://stackoverflow.com/questions/21277806/fatal-early-eof-fatal-index-pack-failed
git config --global core.compression 0 || true
ulimit -f 2097152 || true
ulimit -c 2097152 || true
ulimit -n 2097152 || true
git config --global http.postBuffer 524288000 || true

# Handling Git "dubious ownership" safely:
#  - By default: DO NOT auto-add safe.directory (security).
#  - Enable by setting: AUTO_SAFE_DIRECTORY=1
AUTO_SAFE_DIRECTORY="${AUTO_SAFE_DIRECTORY:-0}"

COUNTER=0
UPDATED=0
SKIPPED=0
FAILED=0
SAFE_ADDED=0

# Iterate only first-level directories, safely (handles spaces).
# -mindepth 1: excludes DESTINATION_PATH itself
# -maxdepth 1: only immediate children
while IFS= read -r -d '' repo; do
  # Only treat directories containing a .git folder/file as git repos
  if [ ! -e "$repo/.git" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  COUNTER=$((COUNTER + 1))
  echo "Updating repo: $repo..."
  echo ""

  # Use a subshell so a failed cd or git command doesn't break outer loop
  (
    cd "$repo"

    # First, detect whether Git considers this repo "safe" for current user
    # If not safe, optionally add to safe.directory (when AUTO_SAFE_DIRECTORY=1)
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      # Capture stderr to detect "dubious ownership"
      err="$(git rev-parse --is-inside-work-tree 2>&1 >/dev/null || true)"
      if echo "$err" | grep -qi "detected dubious ownership"; then
        echo "ERROR: Git refused to operate due to 'dubious ownership'."
        echo "$err"
        echo ""
        if [ "$AUTO_SAFE_DIRECTORY" = "1" ]; then
          echo "AUTO_SAFE_DIRECTORY=1 -> adding to global safe.directory:"
          git config --global --add safe.directory "$repo"
          echo "Added safe.directory: $repo"
          echo ""
        else
          echo "Fix options:"
          echo "  1) Preferred: fix ownership/permissions for this folder (chown/chmod)."
          echo "  2) Add exception (per repo):"
          echo "     git config --global --add safe.directory \"$repo\""
          echo "  3) If you really want auto-add, re-run with:"
          echo "     AUTO_SAFE_DIRECTORY=1 $0 \"$DESTINATION_PATH\""
          echo ""
          exit 2
        fi
      else
        # Some other issue (not a git repo, corrupted repo, etc.)
        echo "ERROR: Not a valid git repository or cannot access: $repo"
        echo "$err"
        exit 3
      fi
    fi

    # If we auto-added safe.directory above, we should re-check access
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "ERROR: Still cannot operate in repo after safe.directory handling: $repo"
      exit 4
    fi

    # Track whether we added safe.directory (best-effort)
    if [ "$AUTO_SAFE_DIRECTORY" = "1" ]; then
      # If this repo appears in global safe.directory now, count it
      if git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "$repo"; then
        # Not perfect (might have been added earlier), but good enough
        :
      fi
    fi

    # Git operations (same semantics as your original script)
    git fetch --all
    git reset --hard HEAD
    git pull
  )
  status=$?

  if [ $status -eq 0 ]; then
    UPDATED=$((UPDATED + 1))
    echo ""
    echo "$repo updated"
    echo "---------------------------------------------------"
    echo ""
  else
    FAILED=$((FAILED + 1))
    echo ""
    echo "FAILED to update: $repo (exit code: $status)"
    echo "---------------------------------------------------"
    echo ""
    # Continue with next repo
  fi
done < <(find "$DESTINATION_PATH" -mindepth 1 -maxdepth 1 -type d -print0)

echo "Repos scanned (git repos found): $COUNTER"
echo "Updated successfully:          $UPDATED"
echo "Skipped (non-git dirs):        $SKIPPED"
echo "Failed:                        $FAILED"
echo "Done"
