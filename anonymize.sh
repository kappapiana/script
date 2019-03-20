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

if [[ $(file --mime-type -b "$1") != application/vnd.oasis.opendocument.text ]];
then

	echo "+**************************************************+"
	echo "WARNING: WRONG DOCUMENT														 |"
	echo "wrong document type: not OpenDocument text (odt)   |"
	echo "+**************************************************+"

	exit

else

	# checking if variables are all filled in

	if [ "$1" = "" ]; then

		echo ""
		echo "+----------------------------------------------------------------"
		echo "|"
		echo "| missing variable (1 required)"
		echo "|"
		# echo "| usage: [scriptname] [filename] [\"replaced with\"] "
		echo "| usage: [scriptname] [filename]  "
		echo "|"
		echo "+----------------------------------------------------------------"
		echo ""
	else

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

		echo 'Please enter your choice: '
		options=("Change all" "Change only one")
		select opt in "${options[@]}"
		do
			case $opt in
				"Change all")
				echo "you chose to change all names with one name"
				break
				;;
				"Change only one")
				echo "you chose to change only one name"
				break
				;;
				*) echo "invalid option $REPLY";;
			esac
		done


		# Now we create a list of authors of modifications

		grep -hoP "<dc:creator>.*?</dc:creator>" $zipdir -R | sort | uniq | sed -E 's@<dc:creator>(.*)</dc:creator>@\1@g' > $zipdir/authors.txt

		echo "these are the names I have found and are going to be replaced"
		echo "+----------------------------------------------------------------"
		cat $zipdir/authors.txt
		echo "+----------------------------------------------------------------"
	# Now we ask for input



		if [ "$REPLY" = "1" ]; then

			echo "Please insert the name you want to be the one displayed in revisions"

			read varname

			echo Thanks, we are going to replace everything with $varname


		cat $zipdir/authors.txt | while  read i ; do

			sed  -i -e s/"$i"/"$varname"/g $zipdir/*.xml

			done

		else

			echo "Please insert the name you want to be replaced"

			read varname2

			echo "Now. please insert the name you want to be the one displayed in revisions"

			read varname

			sed -i -e s/"$varname2"/"$varname"/g $zipdir/*.xml

		fi

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
		echo "But will you?"
		echo ""

		# Uncomment to clear up the temporary directory
		# rm $zipdir

	fi

fi
