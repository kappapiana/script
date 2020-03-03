# !/bin/bash

# Fast wrapper to execute sync across all the repositories in a git
# base directory. Run it from your "git" directory, where git/$repository
# is the structure. Assuming script is the repo where the sync script is.

find -maxdepth 1 -mindepth 1 -type d | while read i ; do

  cd $i
  pwd
  ../script/git_sync_with_remote.sh
  cd ..
done
