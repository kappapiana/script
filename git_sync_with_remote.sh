#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 76)
normal=$(tput sgr0)
bold=$(tput bold)
underline=$(tput sgr 0 1)


if [ ! -z $1 ] ; then
  repo_name=$1
  printf " \n"
  printf "%s\t%s\n" "${bold}operating from${normal}" "$repo_name"
  printf "%s\n" "-------------------------------------------------------------------" ""
else
  repo_name=$(pwd)
  printf " \n"
  printf "%s\t%s\n" "${bold}operating from${normal}" "$repo_name"
  printf "%s\n" "-------------------------------------------------------------------" ""
fi

# delete local branches that have been deleted on remote repo
git -C $repo_name branch -vv | grep gone | awk '{ print $1 }' | xargs -n 1 git -C $repo_name branch -D
# add all branches from remote
git -C $repo_name branch -r | grep -v '\->' | grep "origin/" | \
  while read remote; do
    git -C $repo_name branch --track "${remote#origin/}" "$remote"
  done

default_branch=$(git -C $repo_name remote show origin | grep "HEAD branch" | cut -d ":" -f 2)
# checkout default branch
git -C $repo_name checkout $default_branch
git -C $repo_name pull origin $default_branch
#  fetch and pull all branches
git -C $repo_name fetch --all -p
git -C $repo_name pull --all
