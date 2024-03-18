#!/bin/bash
# https://github.com/bormaxi8080/git-repos-updater.git

#set -e

if [ ${#@} -lt 1 ]; then
    echo "usage: $0 [DESTINATION PATH]"
    exit 1;
fi

# set GitHub options
# https://stackoverflow.com/questions/21277806/fatal-early-eof-fatal-index-pack-failed
git config --global core.compression 0
ulimit -f 2097152
ulimit -c 2097152
ulimit -n 2097152

# git config --show-origin core.packedGitLimit
# git config --unset --global core.packedGitLimit
# git config --global http.postBuffer 2M
git config --global http.postBuffer 524288000

# destination repositories folder
# DESTINATION_PATH="/Volumes/Transcend/repos"
DESTINATION_PATH=$1

echo "This is script for reset --hard HEAD update all git local repositories placed in specified folder"
echo "DESTINATION PATH: $DESTINATION_PATH"
echo "---------------------------------------------------"
echo ""

# repositories counter
COUNTER=0;

# shellcheck disable=SC2044
for repo in $(find "$DESTINATION_PATH" -depth 1 -type d)
do
  echo "Updating repo: $repo..."
  echo ""

  # shellcheck disable=SC2164
  cd "$repo";

  git fetch --all;
  git reset --hard HEAD;
  git pull;

  echo ""
  echo "$repo updated";
  echo "---------------------------------------------------"
  echo ""

  cd ../

  # shellcheck disable=SC2219
  let "COUNTER+=1";
done

echo "$COUNTER repos updated"
echo "Done"