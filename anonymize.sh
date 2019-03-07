#!/bin/bash

	echo ""
	echo "+*******"
	echo "©2018 Carlo Piana, licensed under Creative Commons Zero (CC0)"
	echo "free to use, modify and distribute for any use"
	echo "no string attached"
	echo "+*******"
	echo ""
	echo ""
	echo ""

sleep 1.5 # Waits 1.5 second

#checking if correct filetype

if [[ $(file --mime-type -b "$1") != application/vnd.oasis.opendocument.text ]];
then

	echo "+*******"
	echo "WARNING: WRONG DOCUMENT"
	echo "wrong document type: not OpenDocument text (odt) "
	echo "+*******"

	exit

else

#checking if variables are all filled in

# if [ "$3" = "" ]; then
#
# 	echo ""
# 	echo "+*******"
# 	echo "|"
# 	echo "| missing variable (3 required)"
# 	echo "|"
# 	echo "| usage: [scriptname] [filename] [\"name to be replaced\"] [\"replaced with\"] "
# 	echo "|"
# 	echo "+******"
# 	echo ""
# else

# let's create a directory. If it's already there, who cares. Let's just have an error. Errors are cool!

mkdir /tmp/libreoffice

# some variables that will be used

filename=_anonymized_$1
curdir=`pwd`
zipdir=/tmp/libreoffice

# ok, we're ready, let's meddle with the content!

cp "$1" "$filename"

unzip -oq "$filename" -d $zipdir

grep -hoP "<dc:creator>.*?</dc:creator>" $zipdir -R | sort | uniq | sed -E 's@<dc:creator>(.*)</dc:creator>@\1@g' > $zipdir/authors.txt

cat $zipdir/authors.txt | while  read i ; do

 sed  -i -e s/"$i"/"$3"/g $zipdir/*.xml

done

# this is a dirty hack, because I could not add to zipfile from outside the directory
# basing the directory with -b did not work hell knows why
# I am SO LAME


cd "$zipdir"

zip -fq  "$curdir/$filename" *.xml

cd "$curdir"

echo "done"

echo ""

echo "***WARNING***  Newfile is in $curdir/$filename"
echo ""
echo "Please move it back to the original filename, if you want to perform further changes"

echo ""

fi

# fi
