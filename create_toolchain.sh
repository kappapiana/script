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


# The following code has been commented for user-only install
# It supposes the machine has already everything needed.
# You need root powers to run this part, after uncommenting

# pandoc-crossref (not in the official distribution)

wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.4.1a/linux-pandoc_2_7_3.tar.gz

tar -xf linux-pandoc_2_7_3.tar.gz

sudo mv pandoc-crossref /usr/local/bin

# install pandoc via binary

wget https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-1-amd64.deb

sudo dpkg -i pandoc-2.7.3-1-amd64.deb

# let's update the repositories

sudo apt update

# this is required for the entire environment

sudo apt install -y python-pip python3-pip python3-setuptools python-setuptools make-guile

# Always use one or the other: pandoc-vex is deprecated (legacy)
# pandoc-secgroups is the way to go

wget https://raw.githubusercontent.com/alpianon/pandoc-secgroups/master/pandoc-secgroups
sudo cp pandoc-secgroups /usr/local/bin/ && sudo chmod +x /usr/local/bin/pandoc-secgroups

wget https://raw.githubusercontent.com/alpianon/pandoc-vex/master/pandoc-vex
sudo cp pandoc-vex /usr/local/bin/ && sudo chmod +x /usr/local/bin/pandoc-vex


# and now the filters (as normal user, better)

pip install --user wheel

pip3 install --user wheel

sudo pip install include-pandoc

pip3 install --user panflute

pip3 install --user pandoc-inline-headers

pip3 install --user pandoc-mustache

#separate include-pandoc --update as it doesn't work clean in &&
sudo include-pandoc --update


# cleanup:

rm pandoc-vex
rm linux-pandoc_2_7_3.tar.gz
rm pandoc-2.7.3-1-amd64.deb

# uncomment if you have atom installed!
# apm install alpianon/atom-inline-git-diff
