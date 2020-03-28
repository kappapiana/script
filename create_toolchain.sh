#!/bin/bash

echo "***WARNING***:

this script is meant to produce something usable
for a Linux Ubuntu 18.4 or after, probably broken anywhere else
please check what it does before installing
It will NOT work on non Debian-based Linux

Do you want to continue? just insert anything
otherwise, ctrl+c  NOW! "


read varname

echo "ok, let's proceed"

# check if script is run as normal user

if [[ $EUID == 0 ]]; then
   echo "This script must NOT be run as root
please switch to your user or avoid using sudo.
You will be asked to authenticate for sudo, if needed"
   exit 1
fi

# We install pandoc-crossref (not in the official distribution) and a recent version of pandoc

filtersdir=~/.pandoc/filters
installdir=/usr/local/bin
tmpdir=/tmp/tmpdir
pandoc_ver=`apt-cache policy pandoc | grep Inst | awk '{print $2}' | awk --field-separator="-" '{print $1}'`C

# create ad go to tempdir

mkdir $tmpdir
cd $tmpdir

# download and install pandoc-crossref if there is none

[ -f $installdir/pandoc-crossref ] || \
( wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.4.1a/linux-pandoc_2_7_3.tar.gz && \
tar -xf linux-pandoc_2_7_3.tar.gz && sudo mv pandoc-crossref $installdir ) || \
echo "something went wront with pandoc-crossref"

# install pandoc via binary, if version insufficient

if  [[ "$pandoc_ver" > 2.7 ]] ; then

  wget https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-1-amd64.deb
  sudo dpkg -i pandoc-2.7.3-1-amd64.deb

fi

# install mustache, any complete version if not there already, even if update in error
# let's update the repositories

which mustache 1>/dev/null  || ( sudo apt update ; sudo apt install ruby-mustache )

# need lua filters and scripts in the right place, if not already!


[ -f $filtersdir/crossref-ordered-list.lua ] || wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/crossref-ordered-list.lua
[ -f $filtersdir/inline-headers.lua ] || wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/inline-headers.lua
[ -f $filtersdir/secgroups.lua ] || wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/secgroups.lua

[ -f $installdir/convert-html2docx-comments.pl ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/convert-html2docx-comments.pl
[ -f $installdir/howdyadoc-legal-convert ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/howdyadoc-legal-convert
[ -f $installdir/howdyadoc-legal-preview ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/howdyadoc-legal-preview
[ -f $installdir/pp-include.pl ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/pp-include.pl

# make stuff executable

sudo chmod +x $installdir/*

# cleanup:

rm -rf $tmpdir

# uncomment if you have atom installed!
# apm install alpianon/atom-inline-git-diff

echo "ok, everything should be installed now. Fingers crossed!"

echo "BYE!"
