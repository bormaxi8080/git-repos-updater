#!/bin/bash
# git-repos-updater (safe + robust)

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

# Optional: set AUTO_SAFE_DIRECTORY=1 to auto-add safe.directory for repos that trigger dubious ownership
AUTO_SAFE_DIRECTORY="${AUTO_SAFE_DIRECTORY:-0}"

echo "This script resets local changes (reset --hard HEAD) and updates git repositories in a folder (git fetch --all + git pull)."
echo "DESTINATION PATH: $DESTINATION_PATH"
echo "AUTO_SAFE_DIRECTORY: $AUTO_SAFE_DIRECTORY"
echo "---------------------------------------------------"
echo ""

# Git transport tweaks (kept from your original)
git config --global core.compression 0 || true
ulimit -f 2097152 || true
ulimit -c 2097152 || true
ulimit -n 2097152 || true
git config --global http.postBuffer 524288000 || true

COUNTER=0
UPDATED=0
SKIPPED=0
FAILED=0

# Only immediate child directories; NUL-delimited to survive spaces/newlines in names
while IFS= read -r -d '' repo; do
  # Confirm it's a valid git work tree (this prevents false positives even if .git exists but is broken)
  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Skipping (not a valid git repo): $repo"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  COUNTER=$((COUNTER + 1))
  echo "Updating repo: $repo..."
  echo ""

  # Run update steps; capture failure but continue loop
  if ! (
    cd "$repo"

    # If Git blocks due to dubious ownership, optionally add safe.directory and retry
    if ! git status >/dev/null 2>&1; then
      err="$(git status 2>&1 >/dev/null || true)"
      if echo "$err" | grep -qi "detected dubious ownership"; then
        echo "ERROR: Git refused due to 'dubious ownership': $repo"
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
          echo "  3) Or run with auto-add:"
          echo "     AUTO_SAFE_DIRECTORY=1 $0 \"$DESTINATION_PATH\""
          echo ""
          exit 2
        fi
      else
        # Some other error (rare), treat as failure
        echo "ERROR: Git status failed for repo: $repo"
        echo "$err"
        exit 3
      fi
    fi

    # Update steps (your original semantics)
    git fetch --all
    git reset --hard HEAD
    git pull
  ); then
    UPDATED=$((UPDATED + 1))
    echo ""
    echo "$repo updated"
    echo "---------------------------------------------------"
    echo ""
  else
    FAILED=$((FAILED + 1))
    echo ""
    echo "FAILED to update: $repo"
    echo "---------------------------------------------------"
    echo ""
  fi

done < <(find "$DESTINATION_PATH" -mindepth 1 -maxdepth 1 -type d -print0)

echo "Repos processed (valid git repos): $COUNTER"
echo "Updated successfully:             $UPDATED"
echo "Skipped (non-repos):              $SKIPPED"
echo "Failed:                           $FAILED"
echo "Done"

