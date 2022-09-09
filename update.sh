#!/bin/bash
# https://github.com/bormaxi8080/git-repos-updater.git

# destination repositories folder
# repository="/Volumes/Transcend/repos"
repository=$1

echo "This is script for reset --hard HEAD update all git local repositories placed in specified folder"
echo "Destination folder: $repository"
echo ""

# repositories counter
count=0;

for repo in $(find $repository -depth 1 -type d)
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
  let "count+=1";
done

echo "$count repos updated"
echo "Done"