#!/bin/bash

echo ""
echo "+**************************************************************+"
echo "©2019 Carlo Piana, licensed under Creative Commons Zero (CC0)"
echo "free to use, modify and distribute for any use"
echo "no string attached"
echo "Alpha software, features not consolidated yet"
echo "this file has been modified"
echo "+**************************************************************+"
echo ""

sleep 1.5 # Waits 1.5 second

#checking if correct filetype


# let's create a directory. If it's already there, who cares. Let's just have an error. Errors are cool!

		mkdir /tmp/libreoffice 2&> /dev/null

		# some variables that will be used

		filename=_anonymized_$1
		curdir=`pwd`
		zipdir=/tmp/libreoffice

		# ok, we're ready, let's meddle with the content!

		cp "$1" "$filename"

		unzip -oq "$filename" -d $zipdir

		# Mock select menu


		# Now we create a list of authors of modifications



		sed -i -e s/"sec%3A"/"sec:"/g $zipdir/word/document.xml

		# this is a dirty hack, because I could not add to zipfile from outside the directory
		# basing the directory with -b did not work hell knows why
		# I am SO LAME


		cd "$zipdir"

		rm "$curdir/$filename"

		zip -qr  "$curdir/$1" *

		cd "$curdir"

		echo "done"

 rm $zipdir
