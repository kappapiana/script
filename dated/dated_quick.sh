#!/usr/bin/env bash

# SPDX-FileCopyrightText: Carlo Piana, Federico Edo Granata
#
# SPDX-License-Identifier: BSD-2-Clause

bold=$(tput bold)
normal=$(tput sgr0)

while getopts ":h" option; do
   case ${option} in

      h) # display Help

printf "\n+---------------------------------------------------------+ \n"
echo """
usage: insert the date in the STRING format for date
if you want to enter a ${bold}different timezone${norma} to convert FROM
just add it as a ${bold}second${normal} variable.

Encapsulate variables within quotation marks.

example: ./dated_quick.sh "2022-11-04 11:29" "America/New_York"

Otherwise, just leave entry blank and you will be asked both time and timezone

If you don't know what to enter for timezone, leave also this blank and
you'll be asked

"""
printf "+---------------------------------------------------------+ \n"

         exit;;

   esac
done

set -e  # fails on error

# extracts the continent list
continent_list=`timedatectl list-timezones | cut -f 1 -d / | sort | uniq`

# add to the list of continents the 'exit' option
continent_list="$continent_list exit"

function enter_continentcity() {
  #statements
    # show the list of the continents to select from
    PS3="Enter Continent (exit to exit program):"
    select continent in $continent_list
    do
        # if the user selected 'exit' then exit the script
        if [ "$continent" = "exit" ]; then
            exit
        fi
        # if the user selects a continent, then show the list of timezones
        # in that continent
        if [ -n "$continent" ]; then
            timezone_list=`timedatectl list-timezones | grep $continent | cut -f 2 -d / | sort`
            # add to the list of timezones the 'exit' option
            timezone_list="BACK $timezone_list"
            # show the list of timezones to select from
            PS3="Enter City (1: back to continent selection):"
            select city in $timezone_list; do
                # if the user selected 'back' then go back to selecting the continent
                # if the user selects a city, then convert the date
                # to that timezone
                if [ -n "$city" ]; then
                  TZ=$continent/$city
                else
                  continue
                fi

                break
              done
          fi
          break
      done
    }


# If nothing is entered in the string, ask user

if [ -z "$1" ]; then

  echo "enter date: "
  read date

  echo "enter timezone (leave blank for menu)"
  read TZ

  if [ -z $TZ ]; then
  printf "\nSelect continent and city:\n\n"

      enter_continentcity

      # use while loop to remain in the upper menu if BACK is entered

      while  [ "$city" == "BACK" ]; do
          enter_continentcity
      done

            printf "\nYou have selected: \n${bold}$TZ ${normal}Timezone\n\n"
          fi

else # User has entered at least one string, just use what user passed

  date="$1"

  if [ -n "$2" ]; then
    TZ="$2"
  fi

fi

if [ -n "$TZ" ]; then

  input_date="TZ=\"$TZ\" $date"
  # echo "$1"
else
  input_date="$date"
  # echo "vuota"
fi


printf "+---------------------------------------------------------+ \n"
printf "Original date: $input_date \n"
printf "+---------------------------------------------------------+ \n"

printf "+---------------------------------------------------------+ \n"
printf "Universal Coordinated time: $(date -d "$input_date" +"%Y-%m-%d %T %Z" -u) \n"
printf "+---------------------------------------------------------+ \n"


export TZ='Europe/Amsterdam'
printf "\nCentral European Time: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='America/Los_Angeles'
printf "Los Angeles: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z") \n"

export TZ='America/New_York'
printf "New York: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z") \n"

export TZ='Asia/Tokyo'
printf "Tokyo: \t\t $(date -d "$input_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Australia/Sydney'
printf "Sydney: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Europe/London'
printf "London: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Europe/Dublin'
printf "Dublin: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Europe/Moscow'
printf "Moscow: \t $(date -d "$input_date" +"%Y-%m-%d %T %Z" ) \n"
