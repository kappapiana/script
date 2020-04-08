#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 76)
normal=$(tput sgr0)
bold=$(tput bold)
# underline=$(tput sgr 0 1)

# instout="install_output.log"
# insterr="install_error.log"
declare -a authors_array=()
author_string=""

i_ok() { printf "${green}✔${normal}\n"; }
i_ko() { printf "${red}✖${normal}\n...exiting, check logs"; }


# some variables that will be used and make sure the zip dir exists

curdir=`pwd`
filename="_anonymized_$1"
zipdir="/tmp/libreoffice"

mkdir $zipdir 2&> /dev/null
rm -rf ${zipdir:?}/*

function check_i {
  if [ $? -eq 0 ]; then
    i_ok
  else
    i_ko; read -r
    exit
  fi
}


function list_authors {

mapfile -t authors_array < <(grep -hoP "$author_string" $zipdir -R | sort | uniq | sed -E "s@$author_string@\1@g")

			echo "+----------------------------------------------------------------"
			printf "authors are: "
      printf "%s, " "${authors_array[@]}"
      printf "\n"
			echo "+----------------------------------------------------------------"
}

function change_all {

	printf "Please insert the name you want to be ${red}the only one${normal} displayed in revisions \n"

	printf "instead of all these\\n"

	list_authors

	read -r name_to

	printf "\\nThanks, we are going to replace everything with ${green}$name_to${normal} \\n"

	for i in "${authors_array[@]}" ; do

		for d in $zipdir/*/ ; do

			sed -i -e s/"[\"|\>]$i"/"\"$name_to"/g $d/*.xml ; done


		sed -i -e s/"$i"/"$name_to"/g $zipdir/*.xml

	done

}

function choose_subs { # FIXME: make the choice only from the authors_array array

	printf "Please insert the name you want to be replaced\\n:> "

		read -r name_from

    until [[ " ${authors_array[*]} " =~  ${name_from}  ]]; do

    printf "${name_from} is not a name of authors (${bold}case sensitive!${normal}), \\nplease choose one of "
    printf "%s, " "${authors_array[@]}"
    printf "\\n:> "

    read -r name_from ; done

	printf "Now. please insert the name you want to be the one displayed in revisions \ninstead of ${name_from} \\n:> "

		read -r name_to

		for d in $zipdir/*/ ; do

		sed -i -e s/"[\"|\>]$name_from"/"\"$name_to"/g $d/*.xml ; done

		sed -i -e s/"$name_from"/"$name_to"/g $zipdir/*.xml

}

clear

# Checking the required number of variables

[ ! -z $1 ] && printf "\nFilename is present "|| (printf "missing variable, sucker, a namefile is expected " && exit 1)
check_i

#checking if correct filetype

if
[[ $(file --mime-type -b "$1") =~ application/vnd.oasis.opendocument.text ]] ; then

printf "\\nGood file type ODT"

author_string="<dc:creator>(.*?)</dc:creator>"

elif

[[ $(file --mime-type -b "$1") =~ application/vnd.openxmlformats-officedocument.wordprocessingml.document ]]; then

printf "\\nGood filetype OOXML "

author_string="w:author=\"(.*?)\""

else
	 (printf "\\nNot an ODT or OOXML document " && exit 1)
fi
check_i

printf "\nThis is the list of current authors,
now you will be asked to chose what you want to make of them: \n"

 unzip -oq "$1" -d $zipdir

 list_authors

# ok, we're ready, let's meddle with the content!



# Mock select menu

printf "Please enter your choice: \\n\\n"
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

 	list_authors

 	change_all

	printf "now the list of authors is: \\n"

	list_authors

  else

    printf "Please insert the name you want to be ${red}changed from ${normal} in the following list \n"

    list_authors

    choose_subs

    printf "now the list of authors is: \\n"

    list_authors

    until [[ $choice =~ [YyNn] ]]; do
      printf "\nContinue with new changes? (Y/n) "; read -r -n1 choice
    done

    until [[ $choice =~ [Nn] ]]; do

      printf "\\n these the authors you can change: \\n"
      list_authors

      choose_subs

      printf "\\n these current authors: \\n"
      list_authors
      printf "\\n do you want to continue?" ; read -r -n1 choice

    done

  fi

		# this is a dirty hack, because I could not add to zipfile from outside the directory
		# basing the directory with -b did not work hell knows why
		# I am SO LAME

		# cp $1 $filename # needed to have correct structure FIXME

		cd "$zipdir" || exit # in case cd fails

		# touch "$curdir/$filename"
    rm "$curdir/$filename"


    find -print | zip "$curdir/$filename" -@

		cd "$curdir" || exit # in case it fails

echo "

${green}Script complete${normal}

***WARNING***  Newfile is in $curdir/${bold}$filename${normal}

Please move it back to the original filename
"
