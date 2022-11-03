#!/usr/bin/env bash

# SPDX-FileCopyrightText: Carlo Piana, Federico Edo Granata
#
# SPDX-License-Identifier: BSD-2-Clause


bold=$(tput bold)
normal=$(tput sgr0)
to_or_from="ENTERME"

echo "$2"
set -e  # fails on error

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

function get_values() {
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

                printf "\nYou have selected: \n${bold}$timezone ${normal}Timezone\n\n"
            from_timezone=$timezone

          else
            from_timezone=$TZ
      fi
              }

function enter_to_timezone() {

    to_or_from="${bold}TO which${normal} time will be translated"

    printf "\n\nEnter the timezone ${bold}to which${normal} the time must be translated\n\n"

    enter_continentcity

    to_or_from="CHANGEME"
    totimezone="$timezone"
  }

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

if [ -z $1 ] ; then
    to_or_from="${bold}FROM which${normal} time will be translated"
    get_values
    to_or_from="CHANGEME"
fi



if [ $do_time == "true" ]; then
  enter_to_timezone
  echo "Timezone to is $totimezone"
fi
