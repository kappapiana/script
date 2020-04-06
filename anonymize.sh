#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 76)
normal=$(tput sgr0)
bold=$(tput bold)
underline=$(tput sgr 0 1)

instout="install_output.log"
insterr="install_error.log"

i_ok() { printf "${green}✔${normal}\n"; }
i_ko() { printf "${red}✖${normal}\n...exiting, check logs"; }


# some variables that will be used and make sure the zip dir exists

curdir=`pwd`
filename="_anonymized_$1"
zipdir="/tmp/libreoffice"

mkdir $zipdir 2&> /dev/null
rm -rf $zipdir/*

function check_i {
  if [ $? -eq 0 ]; then
    i_ok
  else
    i_ko; read
    exit
  fi
}

function list_authors {

			grep -hoP "<dc:creator>.*?</dc:creator>" $zipdir -R | sort | uniq | sed -E 's@<dc:creator>(.*)</dc:creator>@\1@g' > $zipdir/authors.txt

			echo "+----------------------------------------------------------------"
			cat $zipdir/authors.txt
			echo "+----------------------------------------------------------------"
}

function choose_subs {

	echo "Please insert the name you want to be replaced"

		read varname2

	echo "Now. please insert the name you want to be the one displayed in revisions"

		read varname

		sed -i -e s/"$varname2"/"$varname"/g $zipdir/*.xml

}

# Checking the required number of variables

[ ! -z $1 ] && printf "\nok, variable is present, good "|| (printf "missing variable, sucker, a namefile is expected " && exit 1)
check_i

#checking if correct filetype

[[ $(file --mime-type -b "$1") == "application/vnd.oasis.opendocument.text" ]] || (printf "\\nNot an ODT document " && exit 1)
check_i

printf "\nThis is the list of current authors,
now you will be asked to chose what you want to make of them: \n"

unzip -oq "$1" -d $zipdir

list_authors

# ok, we're ready, let's meddle with the content!



# Mock select menu

echo 'Please enter your choice: '
options=("Change all" "Change only one")
select opt in "${options[@]}"
do
	case $opt in
		"Change all")
		echo "you chose to change ${bold}all names${normal} with one name"
		break
		;;
		"Change only one")
		echo "you chose to change ${bold}only one${normal} name"
		break
		;;
		*) echo "invalid option $REPLY";;
	esac
done


	# Now we ask for input



		if [ "$REPLY" = "1" ]; then

			printf "Please insert the name you want to be ${red}the only one${normal} displayed in revisions \n"

			printf "instead of all these\\n"

			list_authors

			read varname

			printf "\\nThanks, we are going to replace everything with ${green}$varname${normal} \\n"


		cat $zipdir/authors.txt | while  read i ; do

			sed  -i -e s/"$i"/"$varname"/g $zipdir/*.xml

			done

		else

			printf "Please insert the name you want to be ${red}changed from ${normal} in the following list \n"

			list_authors

			choose_subs

			until [[ $choice =~ [YyNn] ]]; do
      printf "\nContinue with new changes? (Y/n) "; read -n1 choice
			done

			if [[ $choice =~ [Yy] ]]; then

				printf "\\n these are the remaining authors: \\n"
				list_authors

				choose_subs
			fi
		fi

		# this is a dirty hack, because I could not add to zipfile from outside the directory
		# basing the directory with -b did not work hell knows why
		# I am SO LAME

		cp $1 $filename # needed to have correct structure FIXME
		cd "$zipdir"

		touch "$curdir/$filename"
    
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
