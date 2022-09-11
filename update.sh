#!/bin/bash
# https://github.com/bormaxi8080/git-repos-updater.git

set -e

if [ ${#@} -lt 1 ]; then
    echo "usage: $0 [DESTINATION PATH]"
    exit 1;
fi

# destination repositories folder
# DESTINATION_PATH="/Volumes/Transcend/repos"
DESTINATION_PATH=$1

echo "This is script for reset --hard HEAD update all git local repositories placed in specified folder"
echo "DESTINATION PATH: $DESTINATION_PATH"
echo "---------------------------------------------------"
echo ""

# repositories counter
COUNTER=0;

for repo in $(find $DESTINATION_PATH -depth 1 -type d)
do
  echo "Updating repo: $repo..."
  echo ""

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