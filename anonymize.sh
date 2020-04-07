#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 76)
normal=$(tput sgr0)
bold=$(tput bold)
underline=$(tput sgr 0 1)

instout="install_output.log"
insterr="install_error.log"
declare -a authors_array=()

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

authors_array=( `grep -hoP "<dc:creator>.*?</dc:creator>" $zipdir -R | sort | uniq | sed -E 's@<dc:creator>(.*)</dc:creator>@\1@g'` )

			echo "+----------------------------------------------------------------"
			echo "authors are: ${authors_array[@]}"
			echo "+----------------------------------------------------------------"
}



function choose_subs { # FIXME: make the choice only from the authors_array array

	printf "Please insert the name you want to be replaced\\n:> "

		read name_from

    until [[ " ${authors_array[@]} " =~ " ${name_from} " ]]; do

    printf "${name_from} is not a name of authors (${bold}case sensitive!${normal}), \\nplease choose one of "
    printf "%s, " "${authors_array[@]}"
    printf "\\n:> "

    read name_from ; done

	printf "Now. please insert the name you want to be the one displayed in revisions \ninstead of ${name_from} \\n:> "

		read name_to

		sed -i -e s/"$name_from"/"$name_to"/g $zipdir/*.xml

}

clear

# Checking the required number of variables

[ ! -z $1 ] && printf "\nFilename is present "|| (printf "missing variable, sucker, a namefile is expected " && exit 1)
check_i

#checking if correct filetype

[[ $(file --mime-type -b "$1") == "application/vnd.oasis.opendocument.text" ]] && printf "\\nGood filename " || (printf "\\nNot an ODT document " && exit 1)
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

    printf "Please insert the name you want to be ${red}the only one${normal} displayed in revisions \n"

    printf "instead of all these\\n"

    list_authors

    read name_to

    printf "\\nThanks, we are going to replace everything with ${green}$name_to${normal} \\n"

    for i in "${authors_array[@]}" ; do

      sed  -i -e s/"$i"/"$name_to"/g $zipdir/*.xml

    done

  else

    printf "Please insert the name you want to be ${red}changed from ${normal} in the following list \n"

    list_authors

    choose_subs

    printf "now the list of authors is: \\n"

    list_authors

    until [[ $choice =~ [YyNn] ]]; do
      printf "\nContinue with new changes? (Y/n) "; read -n1 choice
    done

    until [[ $choice =~ [Nn] ]]; do

      printf "\\n these the authors you can change: \\n"
      list_authors

      choose_subs

      printf "\\n these current authors: \\n"
      list_authors
      printf "\\n do you want to continue?" ; read -n1 choice

    done

  fi

		# this is a dirty hack, because I could not add to zipfile from outside the directory
		# basing the directory with -b did not work hell knows why
		# I am SO LAME

		cp $1 $filename # needed to have correct structure FIXME
		cd "$zipdir"

		touch "$curdir/$filename"

		zip -fq  "$curdir/$filename" *.xml

		cd "$curdir"


echo "

${green}Script complete${normal}

***WARNING***  Newfile is in $curdir/${bold}$filename${normal}

Please move it back to the original filename
"
