#!/usr/bin/env bash

# SPDX-FileCopyrightText: Carlo Piana, Federico Edo Granata
#
# SPDX-License-Identifier: BSD-2-Clause


bold=$(tput bold)
normal=$(tput sgr0)
to_or_from="ENTERME"
do_time="nothing"


set -e  # fails on error

while getopts "ht" opt; do
   case ${opt} in

     h)
      echo "this is help"
        exit
      ;;

     t)
     do_time="true"
     ;;
    esac
  done

  shift $((OPTIND - 1)) # use positional arguments again


# transform positional into named variables for good sake
prompted_time=$1
prompted_TZ=$2

if [[ -n $3 ]]; then
  echo """
    too many variables, anything after and including "${bold}$3${normal}" is meaningless
    have you quoted (eg \"date time\") the time you have entered?
    """

  exit
fi

# extracts the continent list
continent_list=`timedatectl list-timezones | cut -f 1 -d / | sort | uniq`

# add to the list of continents the 'exit' option
continent_list="$continent_list exit"

function enter_continentcity() {
  #statements
    # show the list of the continents to select from
    PS3="Enter Continent (exit to exit program) $to_or_from:"
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
                  timezone=$continent/$city
                else
                  continue
                fi

                break
              done
          fi
          break
      done
    }

# To enter date and timezone FROM which date will be calcluated
# $from_timezone and $date are set.
function get_values() {

  if  [ -z $prompted_time ] ; then

    echo "enter date: "
    read date
  else
    echo "From date is already enterd, move on"
    date="$prompted_time"
  fi

  if [[ -z $prompted_TZ ]]; then
    echo "enter timezone (leave blank for menu)"
    read TZ
    from_timezone="$TZ"
  else
    echo "From timezone e is already enterd, move on"
    from_timezone="$prompted_TZ"
  fi

  if [[ -z $from_timezone ]] ; then

    #statements
    printf "\nSelect continent and city:\n\n"

    enter_continentcity

      # use while loop to remain in the upper menu if BACK is entered

      while  [ "$city" == "BACK" ]; do
          enter_continentcity
      done

      printf "\nYou have selected: \n${bold}$timezone ${normal}Timezone\n\n"
      from_timezone=$timezone
    fi

              }

# To enter date and timezone TO which date will be calcluated
# $to_timezone is set.
function enter_to_timezone() {

    # modify the prompt
    to_or_from="${bold}TO which${normal} time will be translated"

    printf "\n\nEnter the timezone ${bold}to which${normal} the time must be translated\n\n"

    enter_continentcity

    to_or_from="CHANGEME" # reset the variable
    to_timezone="$timezone"
  }


# modify the prompt
to_or_from="${bold}FROM which${normal} time will be translated"
# interactively enter the timezone to
    get_values
to_or_from="CHANGEME" # reset the variable


# if option is added, target timezone is entered
if [ $do_time = "true" ]; then
  enter_to_timezone
  echo "Timezone to is $to_timezone"
fi

echo "time from is $date "
echo "timezone from is $from_timezone"
echo "timezone to is $to_timezone"


input_date="TZ=\"$from_timezone\" $date"

printf "+---------------------------------------------------------+ \n"
printf "Universal Coordinated time: $(date -d "$input_date" +"%Y-%m-%d %T %Z" -u ) \n"
printf "+---------------------------------------------------------+ \n"

if [[ -n $to_timezone ]]; then
  export TZ="$to_timezone"

  printf "+---------------------------------------------------------+ \n"
  printf "Date of ${to_timezone} is: $(date -d "$input_date" +"%Y-%m-%d %T %Z"  ) \n"
  printf "+---------------------------------------------------------+ \n"

fi

printf "+---------------------------------------------------------+ \n"
echo "OTHER DATES"
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
