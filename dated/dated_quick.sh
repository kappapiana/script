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

else # User has entered at least one string, just use what user passed

  date="$1"

  if [ -n "$2" ]; then
    # echo "piena"
    TZ="$2"
    # echo "$1"
  else
    echo "using system timezone"
  fi

fi

# Now we have both values (including, "no value")

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
