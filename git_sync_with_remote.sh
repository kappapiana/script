#!/bin/bash

# delete local branches that have been deleted on remote repo
git branch -vv | grep gone | awk '{ print $1 }' | xargs -n 1 git branch -D
# add all branches from remote
git branch -r | grep -v '\->' | grep "origin/" | \
  while read remote; do
    git branch --track "${remote#origin/}" "$remote"
  done

default_branch=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2)
# checkout default branch
git checkout $default_branch
git pull origin $default_branch
# fetch and pull all branches
git fetch --all -p
git pull --all

