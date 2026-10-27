#!/bin/bash
#
# dotfiles_safe_pull.sh — pull a bare-repo dotfiles setup without losing local files.
#
# A plain `git pull` on a $HOME work tree has two traps:
#   1. a file the remote stopped tracking (made per-machine) is DELETED from disk;
#   2. a file the remote started tracking that already exists locally aborts the pull.
# This script backs up both kinds, pulls, puts the local per-machine copies back,
# and reports which newly-tracked files differed from the local version.
#
# It also moves the git identity into ~/.gitconfig.local before a pull that would
# replace ~/.gitconfig with a shared one (shared .gitconfig includes ~/.gitconfig.local).
#
# Usage: dotfiles_safe_pull.sh [-d PATH]... [branch]      (default branch: master)
#   -d PATH   file or dir (relative to $HOME) that upstream untracked and you do NOT
#             want to keep: it is backed up, then removed instead of restored.
#             e.g. dotfiles_safe_pull.sh -d .config/gomuks
# Assumes the repo lives in ~/.dotfiles.git with $HOME as work tree.

set -euo pipefail

normal=$(tput sgr0 2>/dev/null || true)
bold=$(tput bold 2>/dev/null || true)

drop=()
while getopts "d:h" opt; do
  case $opt in
    d) drop+=("${OPTARG%/}") ;;
    *) sed -n '3,20p' "$0"; exit 0 ;;
  esac
done
shift $((OPTIND - 1))
branch="${1:-master}"
git_dir="$HOME/.dotfiles.git"
backup_dir="$HOME/.dotfiles-pull-backup/$(date +%Y%m%d-%H%M%S)"

dot() { /usr/bin/git --git-dir="$git_dir" --work-tree="$HOME" "$@"; }

say() { printf "%s\n" "${bold}$*${normal}"; }

backup() { # copy a file into the backup dir, keeping its path relative to $HOME
  mkdir -p "$backup_dir/$(dirname "$1")"
  cp -p "$HOME/$1" "$backup_dir/$1"
}

[ -d "$git_dir" ] || { echo "No dotfiles repo at $git_dir" >&2; exit 1; }
cd "$HOME"

say "Fetching origin/$branch"
dot fetch -q origin "$branch"
remote=FETCH_HEAD

if [ "$(dot rev-list --count HEAD.."$remote")" -eq 0 ]; then
  say "Already up to date."
  exit 0
fi

# Git identity: if the incoming .gitconfig includes ~/.gitconfig.local, save the
# current identity there first, so the shared .gitconfig doesn't drop it.
if dot show "$remote:.gitconfig" 2>/dev/null | grep -q 'gitconfig.local' && [ ! -e .gitconfig.local ]; then
  name=$(git config --global user.name || true)
  email=$(git config --global user.email || true)
  if [ -n "$name$email" ]; then
    printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > .gitconfig.local
    say "Saved git identity to ~/.gitconfig.local ($name <$email>)"
  fi
fi

# Trap 1: tracked here, untracked upstream -> the pull would delete them.
mapfile -t removed < <(comm -23 <(dot ls-tree -r --name-only HEAD | sort) \
                                <(dot ls-tree -r --name-only "$remote" | sort))
keep=()
for f in "${removed[@]}"; do
  [ -e "$f" ] || continue
  backup "$f"
  for d in "${drop[@]}"; do [[ "$f" == "$d" || "$f" == "$d"/* ]] && continue 2; done
  keep+=("$f")
done

# Uncommitted edits block the pull. Edits to files that are becoming per-machine
# are expected (that's why they're leaving the repo): they're backed up, so reset
# them for the pull. Any other edit must be committed first.
blocking=()
while IFS= read -r f; do
  for r in "${removed[@]}"; do
    [ "$r" == "$f" ] && { dot checkout -q -- "$f"; continue 2; }
  done
  blocking+=("$f")
done < <(dot diff --name-only HEAD)
if [ ${#blocking[@]} -gt 0 ]; then
  echo "You have uncommitted dotfiles changes; commit or discard them first:" >&2
  printf '  %s\n' "${blocking[@]}" >&2
  exit 1
fi

# Trap 2: new upstream, already present locally -> move aside so the pull can run.
mapfile -t added < <(comm -13 <(dot ls-tree -r --name-only HEAD | sort) \
                              <(dot ls-tree -r --name-only "$remote" | sort))
moved=()
for f in "${added[@]}"; do
  [ -e "$f" ] || continue
  backup "$f"
  rm "$f"
  moved+=("$f")
done

say "Pulling"
if ! dot pull --no-rebase --no-edit -q origin "$branch"; then
  echo "Pull failed (probably a merge conflict). Your files are backed up in $backup_dir" >&2
  echo "Resolve with: git --git-dir=$git_dir --work-tree=\$HOME status" >&2
  exit 1
fi

# Put back the files that became per-machine. The repo marks those by ignoring
# them; a file that left the repo without being ignored was meant to go away.
restored=()
gone=()
for f in "${keep[@]}"; do
  if dot ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    continue   # still tracked after the merge (e.g. local commits kept it): leave as is
  fi
  if dot check-ignore -q --no-index "$f"; then
    mkdir -p "$(dirname "$f")"
    cp -p "$backup_dir/$f" "$f"
    restored+=("$f")
  else
    gone+=("$f")
  fi
done
[ ${#restored[@]} -gt 0 ] && { say "Kept these now per-machine files:"; printf '  %s\n' "${restored[@]}"; }
[ ${#gone[@]} -gt 0 ] && { say "Deleted from the repo, removed here (backup kept):"; printf '  %s\n' "${gone[@]}"; }
for d in "${drop[@]}"; do
  [ -e "$d" ] && rm -r "$d"
  say "Not kept, as asked with -d: $d (backup kept)"
done

# Report newly tracked files whose local copy differed.
differ=()
for f in "${moved[@]}"; do
  cmp -s "$f" "$backup_dir/$f" || differ+=("$f")
done
if [ ${#differ[@]} -gt 0 ]; then
  say "These files are now tracked and the repo version replaced your local one:"
  printf '  %s\n' "${differ[@]}"
  echo "  Your old versions are in $backup_dir (compare with: diff \"$backup_dir/FILE\" ~/FILE)"
fi

echo
say "Done. git identity here: $(git config user.name || echo '?') <$(git config user.email || echo '?')>"
echo "Backup of everything touched: $backup_dir"
[ -f "$HOME/.bashrc" ] && echo "Open a new terminal (or: source ~/.bashrc) to load shell changes."
