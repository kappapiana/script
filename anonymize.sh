#!/bin/bash

if [ "$3" = "" ]; then

	echo ""
	echo "+*******"
	echo "|"
	echo "| missing variable (3 required)"
	echo "|"
	echo "| usage: [scriptname] [filename] [\"name to be replaced\"] [\"replaced with\"] "
	echo "|"
	echo "+******"
	echo ""
else


mkdir /tmp/libreoffice


filename=_anonymized_$1
curdir=`pwd`
zipdir=/tmp/libreoffice

#echo "dir is $curdir"
#echo "zip dir is $zipdir"
#echo ""

cp $1 $filename

unzip -oq $filename -d $zipdir 

sed -i -e s/"$2"/"$3"/g $zipdir/*.xml

cd $zipdir

zip -fq  $curdir/$filename *.xml

cd $curdir


echo "done"

echo ""

echo "***wARNING***  Newfile is in $curdir/$filename"
echo ""
echo "Please move it back to the original filename, if you want to perform further changes"

echo ""

fi
