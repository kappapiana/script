#!/usr/bin/env bash

# =================================
# Set Variables
# =================================

filtersdir=~/.pandoc/filters
installdir=/usr/local/bin
tmpdir=/tmp/tmpdir
deb_ver=`cat /etc/debian_version`
minversion="2.7" #Minimum version for Pandoc
update_pandoc="false"

# =================================
# Preliminary controls
# =================================

# check if root

if [[ $EUID == 0 ]]; then
  echo "
  ***ERROR***
  Sorry, this script must NOT be run as root:
  please log in as normal user or avoid using sudo.
  You will be asked to authenticate for sudo, if needed"
   exit 1
fi

# Check if Debian

if [ -z $deb_ver ] ; then
  echo "This ain't no Debian-based  -- Aborting" ; exit 1
fi

# check if sudoer

sudo touch /tmp/test 2> /dev/null

if [ $? != 0 ]
then
  echo "
  Oh no, you are not a sudoer
  make sure your user can sudo"
  exit 1
fi

# =================================
# Actual script
# =================================

# we operate from a temporary directory
mkdir $tmpdir
cd $tmpdir
rm $tmpdir/* 2>/dev/null

# Debian packages:

pandoc_ver=`apt-cache policy pandoc | egrep "Inst" | awk '{print $2}' | sed 's/-/./g' | awk 'BEGIN { FS = "." } ; {print $1 "." $2}'`
pandoc_cand=`apt-cache policy pandoc | egrep "Cand" | awk '{print $2}' | sed 's/-/./g' | awk 'BEGIN { FS = "." } ; {print $1 "." $2}'`

if [ $pandoc_ver = "(none)." ] ; then
pandoc_ver=0

fi

# Install pandoc and only if the version in repositories is not sufficiently recent
# fetch it and install manually

if  [[ "$pandoc_ver" < $minversion ]] ; then
  if  [[ "$pandoc_cand" < $minversion ]] ; then

    wget https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-1-amd64.deb
    sudo dpkg -i pandoc-2.7.3-1-amd64.deb

    echo "we have installed Pandoc to $minversion from github (not repositories)"
  else
    update_pandoc="true"
  fi
else
echo "Pandoc is up to the needed version"
update_pandoc="false"
fi

# check if apt cache is sufficiently recent, else, skip
last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin)
now=$(date +%s)
if [ $((now - last_update)) -gt 3600 ]; then
  update_apt="true" ; else
  update_apt="false"
fi


if [ $update_pandoc = "true" ] ; then
 [ $update_apt = "true" ] && sudo apt update && update_apt="false" ; sudo apt install pandoc
fi

which mustache 1>/dev/null  || ( [ $update_apt = "true" ] && sudo apt update ; sudo apt install -y ruby-mustache )

# Now we donwload a bunch of filters and stuff if missing

[ -f $filtersdir/crossref-ordered-list.lua ] || wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/crossref-ordered-list.lua
[ -f $filtersdir/inline-headers.lua ] || wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/inline-headers.lua
[ -f $filtersdir/secgroups.lua ] || wget --directory-prefix=$filtersdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/pandoc-lua-filters/secgroups.lua

[ -f $installdir/convert-html2docx-comments.pl ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/convert-html2docx-comments.pl
[ -f $installdir/howdyadoc-legal-convert ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/howdyadoc-legal-convert
[ -f $installdir/howdyadoc-legal-preview ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/howdyadoc-legal-preview
[ -f $installdir/pp-include.pl ] || sudo wget --directory-prefix=$installdir https://raw.githubusercontent.com/alpianon/howdyadoc/dev-legal/legal/scripts/pp-include.pl


[ -f $installdir/pandoc-crossref ] || \
( wget --directory-prefix=$tmpdir https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.4.1a/linux-pandoc_2_7_3.tar.gz && \
tar -xf $tmpdir/linux-pandoc_2_7_3.tar.gz && sudo mv $tmpdir/pandoc-crossref $installdir ) || \
echo "something went wrong with pandoc-crossref"


# make stuff executable in the install directory

sudo chmod +x $installdir/*


# cleanup temp directory:

sudo rm -rf $tmpdir

echo "
*********************************************
congratulations, your Debian $deb_ver
or Debian based distro can do it!
********************************************
"
