#!/usr/bin/env bash

# =================================
# Set Variables
# =================================

filtersdir=~/.pandoc/filters # lua filters will go here (user only)
installdir=/usr/local/bin # binaries will go here (system-wide)
deb_ver=`cat /etc/debian_version` # find out which Debian are we on
minversion="2.7" #Minimum version for Pandoc
update_pandoc="false" # inizialize variable to default value
red=$(tput setaf 1)
green=$(tput setaf 76)
normal=$(tput sgr0)
bold=$(tput bold)
underline=$(tput sgr 0 1)
logfile="$PWD/create_toolchain.log"
errorlogfile="$PWD/create_toolchain_error.log"

exec 2>>"$errorlogfile"

# =================================
# Silly functions
# =================================

i_ok() { printf "${green}✔${normal}\n"; }
i_ko() { printf "\n  ${red}✖  ERROR  ✖${normal}\n"; }

function check_i {
  if [ $? -eq 0 ]; then
    i_ok
  else
    i_ko; read
    exit
  fi
}

# =================================
# Preliminary checks
# =================================

# check if root

if [[ $EUID == 0 ]]; then
  i_ko
  printf "
  Sorry, this script ${red} must NOT${normal} be run as root:
  please log in as normal user or avoid using sudo.
  You will be asked to authenticate for sudo, if needed\n"
   exit 1
fi

# Check if Debian

if [ -z $deb_ver ] ; then
  i_ko
  printf "\nThis ain't no Debian-based  -- Aborting\n\n" ; exit 1
fi

# check if sudoer

sudo touch /tmp/test 2> /dev/null

if [ $? != 0 ]
then
  i_ko
  printf "\n  Oh no, you are not a sudoer!
  Make sure your user can sudo.
  or add yourself to sudo group. Go back to root and use:
  # usermod -a -G sudo $USER \n\n"
  exit 1
fi

# =================================
# Actual script
# =================================

# we operate from a temporary directory
printf "\ncreating temp dir..."
tmpdir=$(mktemp -d)
cd $tmpdir
check_i

# Debian packages:

# check what pandoc version do we have installed and available
pandoc_ver=`export LANG=en_US.UTF-8; apt-cache policy pandoc | egrep "Inst" | awk '{print $2}' | sed 's/-/./g' | awk 'BEGIN { FS = "." } ; {print $1 "." $2}'`
pandoc_cand=`export LANG=en_US.UTF-8; apt-cache policy pandoc | egrep "Cand" | awk '{print $2}' | sed 's/-/./g' | awk 'BEGIN { FS = "." } ; {print $1 "." $2}'`
[[ $pandoc_ver =~ ^.*none.*$ ]] && pandoc_ver=0 # if no version installed, we need a number

# Install pandoc and only if the version in repositories is not sufficiently recent
# fetch it and install manually

if  [[ "$pandoc_ver" < $minversion ]] ; then
  if  [[ "$pandoc_cand" < $minversion ]] ; then
    printf "downloading pandoc-2.7.3..."
    wget https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-1-amd64.deb 1>>"$logfile" 2>>"$errorlogfile"
    check_i
    printf "installing pandoc..."
    sudo apt-get install -y ./pandoc-2.7.3-1-amd64.deb 1>>"$logfile" 2>>"$errorlogfile"
    check_i
    printf "We have installed Pandoc to $minversion from github (not repositories)"
  else
    update_pandoc="true"
  fi
else
  printf "Pandoc is already up to the needed version "
  i_ok
  update_pandoc="false"
fi

# check if apt cache is sufficiently recent or has it been ever updated, else, skip

[ -f /var/cache/apt/pkgcache.bin ] && last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin) || last_update=0
now=$(date +%s)
[ -f /var/cache/apt/pkgcache.bin ] && actualsize=$(du -k /var/cache/apt/pkgcache.bin | cut -f 1) || actualsize=0 # if size too small, need to force update: check size

if [ $((now - last_update)) -gt 3600 ] || [ ! $actualsize -ge 3000 ] ; then
  update_apt="true" ; else
  update_apt="false"
fi

# If we need to install or update pandoc from repository, we do it now

if [ $update_pandoc = "true" ] ; then
  if [ $update_apt = "true" ]; then
    printf "running apt update..."
    sudo apt update 1>>"$logfile" 2>>"$errorlogfile"
    check_i
    update_apt="false"
  fi
  printf "updating pandoc from repository..."
   sudo apt-get install -y pandoc 1>>"$logfile" 2>>"$errorlogfile"
fi

# test if mustache is installed, if not, install ruby-mustache from repository

if [[ -z "$(which mustache)" ]]; then
  if [ $update_apt = "true" ]; then
    printf "running apt update..."
    sudo apt update 1>>"$logfile" 2>>"$errorlogfile"
    check_i
  fi
  printf "installing ruby-mustache..."
  sudo apt-get install -y ruby-mustache 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

# Now we donwload a bunch of filters and stuff if missing

if [ ! -f $filtersdir/crossref-ordered-list.lua ]; then
  printf "downloading and installing pandoc filter 'crossref-ordered-list.lua'..."
  wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/crossref-ordered-list.lua 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $filtersdir/inline-headers.lua ]; then
  printf "downloading and installing pandoc filter 'inline-headers.lua'..."
  wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/inline-headers.lua 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $filtersdir/secgroups.lua ]; then
  printf "downloading and installing pandoc filter 'secgroups.lua'..."
  wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/secgroups.lua 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $installdir/convert-html2docx-comments.pl ]; then
  printf "downloading and installing script 'convert-html2docx-comments.pl'..."
  sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/convert-html2docx-comments.pl 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $installdir/howdyadoc-legal-convert ]; then
  printf "dowloading script 'howdyadoc-legal-convert'..."
  sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/howdyadoc-legal-convert 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $installdir/howdyadoc-legal-preview ]; then
  printf "downloading and installing script 'howdyadoc-legal-preview'..."
  sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/howdyadoc-legal-preview 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $installdir/pp-include.pl ]; then
  print "downloading and installing script 'pp-include.pl'..."
  sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/pp-include.pl 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

if [ ! -f $installdir/pandoc-crossref ]; then
  print "downloading pandoc filter 'pandoc-crossref'..."
  wget --directory-prefix=$tmpdir https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.4.1a/linux-pandoc_2_7_3.tar.gz 1>>"$logfile" 2>>"$errorlogfile"
  check_i
  print "installing 'pandoc-crossref'..."
  tar -xf $tmpdir/linux-pandoc_2_7_3.tar.gz 1>>"$logfile" 2>>"$errorlogfile" && sudo mv $tmpdir/pandoc-crossref $installdir 1>>"$logfile" 2>>"$errorlogfile"
  check_i
fi

# make stuff executable in the install directory

sudo chmod +x $installdir/*


# installing atom and related stuff, and configure it to use howdyadoc

printf "\nDo you want to configure Atom as a text editor for howdyadoc?"
printf "\n(answer 'n' if this is a server) [y/n] "
until [[ "$configure_atom" =~ [YyNn] ]]; do
  read configure_atom
done
if [[ "$configure_atom" =~ [Yy] ]]; then
  printf "\nInstalling git and pip3..."
  sudo apt-get install -y git python3-pip 1>>"$logfile" 2>>"$errorlogfile"
  check_i
  which atom >/dev/null 2>&1 && atom_installed="true"
  if [[ -z "$atom_installed" ]]; then
    printf "downloading atom..."
    cd $tmpdir
    wget -O atom-amd64.deb https://atom.io/download/deb 1>>"$logfile" 2>>"$errorlogfile"
    check_i
    printf "installing atom..."
    sudo apt-get install -y ./atom-amd64.deb 1>>"$logfile" 2>>"$errorlogfile"
    check_i
  fi
  if [ ! -f ~/.atom/config.cson ]; then
    printf "\nAtom user profile not found!"
    printf "\nPlease hit return, and I will start Atom to create your user profile."
    printf "\nThen, close Atom window after you see the welcome page, so we can go on..."
    read -p -s
    atom -w -f
    printf "User profile created! "
    i_ok
  fi
  installed_packages=$(apm list --packages --installed --enabled --bare)
  if [[ -z "`echo "$installed_packages" | grep "inline-git-diff@3.0.0"`" ]]; then
    printf "downloading howdyadoc fork of 'inline-git-diff' package..."
    mkdir ~/.atom/packages >/dev/null 2>&1
    cd ~/.atom/packages
    git clone https://github.com/alpianon/atom-inline-git-diff.git 1>>"$logfile" 2>>"$errorlogfile"
    check_i
    mv atom-inline-git-diff inline-git-diff
    cd inline-git-diff
    printf "installing downloaded package..."
    apm install 1>>"$logfile" 2>>"$errorlogfile"
    check_i
  fi
  essential_packages=(language-pfm markdown-table-editor markdown-writer platformio-ide-terminal markdown-preview-enhanced)
  for pkg in ${essential_packages[@]}; do
    if [ -z "`echo "$installed_packages" | grep $pkg`" ]; then
      printf "installing atom package '$pkg'..."
      apm install $pkg 1>>"$logfile" 2>>"$errorlogfile"
      check_i
    fi
  done
  printf "installing cson for python..."
  sudo pip3 install cson 1>>"$logfile" 2>>"$errorlogfile"
  check_i
  printf "configuring markdown-preview-enhanced to use howdyadoc..."
  cd ~/.atom
  python3 <<EOT
import cson
with open('config.cson','r') as f: config = cson.load(f)
config['*']['markdown-preview-enhanced'] = {}
config['*']['markdown-preview-enhanced']['pandocPath'] = 'howdyadoc-legal-preview'
config['*']['markdown-preview-enhanced']['usePandocParser'] = True
config['*']['markdown-preview-enhanced']['previewTheme'] = 'atom-dark.css'
with open('config.cson','w') as f: cson.dump(config, f, indent=2)
EOT
  check_i
  printf "\nDo you want to install recommended packages for Atom? [y/n] "
  until [[ "$install_recommended" =~ [YyNn] ]]; do
    read install_recommended
  done
  if [[ "$install_recommended" =~ [Yy] ]]; then
    recommended_packages=(atom-overtype-mode change-case comment git-history magic-reflow open-file random split-diff todo-show)
    for pkg in ${recommended_packages[@]}; do
      if [ -z "`echo "$installed_packages" | grep $pkg`" ]; then
        printf "installing atom package '$pkg'..."
        apm install $pkg 1>>"$logfile" 2>>"$errorlogfile"
        check_i
      fi
    done
  fi
fi

# cleanup temp directory:

rm -rf $tmpdir

printf "******************************************
congratulations, your ${green}Debian${normal} $deb_ver
or Debian based distro can do it!
********************************************
"
