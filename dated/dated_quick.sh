#!/usr/bin/env bash

# simple oneliner to convert date in various time zones

printf "+---------------------------------------------------------+ \n"

echo """
usage: insert the date in the STRING format for date
if you want to enter a different timezone to convert FROM
just add it as a second variable.

Encapsulate variables within quotation marks.

example: ./dated_quick.sh "2022-11-04 11:29" "America/New_York"

Otherwise, just leave entry blank and you will be asked

"""
printf "+---------------------------------------------------------+ \n"

set -e  # fails on error

# If nothing is entered in the string, ask user

if [ -z "$1"]; then

  echo "enter date: "
  read date

  echo "enter timezone (leave blank for current one)"
  read TZ

  if [ -z $TZ ]; then
  echo "TZ vuota"

  # Se non sa, inseriamola noi
    # importa funzione
    continent_list=`timedatectl list-timezones | cut -f 1 -d / | sort | uniq`

    # add to the list of continents the 'exit' option
    continent_list="$continent_list exit"
    # show the list of the continents to select from
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
            select city in $timezone_list; do
                # if the user selected 'back' then go back to selecting the continent
                if [ "$city" = "BACK" ]; then
                    continue
                fi
                # if the user selects a city, then convert the date
                # to that timezone
                if [ -n "$city" ]; then
                    TZ=$continent/$city
                    loc=$(echo "$city" | cut -f 2 -d / | tr '_' ' ')
                fi
            done
        fi
    done
    # fine importa funzione

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

# UTC is always the basis for calculation

utc_date=$(date -d "$input_date" +"%Y-%m-%d %T %Z")


printf "+---------------------------------------------------------+ \n"
printf "Universal Coordinated time: $(date -d "$utc_date" +"%Y-%m-%d %T %Z" -u) \n"
printf "+---------------------------------------------------------+ \n"

printf "European Time: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='America/Los_Angeles'
printf "Los Angeles: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z") \n"

export TZ='America/New_York'
printf "New York: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z") \n"

export TZ='Asia/Tokyo'
printf "Tokyo: \t\t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Australia/Sydney'
printf "Sydney: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Europe/London'
printf "London: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Europe/Dublin'
printf "Dublin: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"

export TZ='Europe/Moscow'
printf "Moscow: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"
