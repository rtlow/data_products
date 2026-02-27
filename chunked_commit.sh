#!/bin/bash

set -e  # Exit immediately on error

BATCH_SIZE=1000
REMOTE="origin"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Ensure we're in a git repo
if [ ! -d ".git" ]; then
  echo "Error: Not inside a git repository."
  exit 1
fi

# Ensure GitHub remote exists
if ! git remote get-url "$REMOTE" > /dev/null 2>&1; then
  echo "Error: Remote '$REMOTE' not found."
  exit 1
fi

echo "Collecting untracked files..."
mapfile -t FILES < <(git ls-files --others --exclude-standard)

TOTAL=${#FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo "No untracked files found."
  exit 0
fi

echo "Found $TOTAL untracked files."
echo "Committing and pushing to GitHub in batches of $BATCH_SIZE..."

START=0
COMMIT_NUM=1
FIRST_PUSH=true

while [ $START -lt $TOTAL ]; do
  BATCH=("${FILES[@]:START:BATCH_SIZE}")

  echo "Committing batch $COMMIT_NUM (${#BATCH[@]} files)..."

  git add "${BATCH[@]}"
  git commit -m "Add batch $COMMIT_NUM (${#BATCH[@]} files)"

  echo "Pushing batch $COMMIT_NUM..."

  if [ "$FIRST_PUSH" = true ]; then
    git push -u "$REMOTE" "$BRANCH"
    FIRST_PUSH=false
  else
    git push "$REMOTE" "$BRANCH"
  fi

  START=$((START + BATCH_SIZE))
  COMMIT_NUM=$((COMMIT_NUM + 1))
done

echo "All batches committed and pushed to GitHub successfully."
