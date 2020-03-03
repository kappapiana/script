#!/bin/bash

# delete local branches that have been deleted on remote repo
git branch -vv | grep gone | awk '{ print $1 }' | xargs -n 1 git branch -D
# add all branches from remote
git branch -r | grep -v '\->' | \
  while read remote; do 
    git branch --track "${remote#origin/}" "$remote" 
  done
# checkout master branch
git checkout master
git pull origin master
# fetch and pull all branches
git fetch --all -p
git pull --all

