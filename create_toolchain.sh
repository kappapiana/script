#!/bin/bash

echo "***WARNING***:

this is an incredible hack
only meant to produce something usable
for a Linux Ubuntu 18.4, probably broken anywhere else
please check what it does before installing

**** important ****
If you are using SUDO to run this script, revert to normal user.
We are sudoing you within the script when necessary, but you need to uncomment

Do you want to continue? just insert anything
otherwise, ctrl+c  NOW! "


read varname

echo "ok, let's proceed"



# We install pandoc-crossref (not in the official distribution) and a recent version of pandoc

filtersdir=~/.pandoc/filters
installdir=/usr/local/bin
tmpdir=/tmp/tmpdir

# create ad go to tempdir

mkdir $tmpdir
cd $tmpdir

wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.4.1a/linux-pandoc_2_7_3.tar.gz

tar -xf linux-pandoc_2_7_3.tar.gz

sudo mv pandoc-crossref $installdir

# install pandoc via binary

wget https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-1-amd64.deb

sudo dpkg -i pandoc-2.7.3-1-amd64.deb

# let's update the repositories

# install mustache, any complete version if not there already, even if update in error
which mustache || ( sudo apt update ; sudo apt install ruby-mustache )

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

sleep 5

echo "BYE!"
