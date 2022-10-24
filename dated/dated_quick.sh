#!/usr/bin/env bash

# simple oneliner to convert date in various time zones

echo  ""
echo "usage: insert the date in the STRING format for date
if you want to enter a different timezone to convert FROM
just add it as a second variable.

Encapsulate variables within quotation marks

example: ./dated_quick.sh "2022-11-04 11:29" "America/New_York""
echo  ""

set -e  # fails on error

if [ -n "$2" ]; then
  echo "piena"
  input_date="TZ=\"$2\" $1"
  # echo "$1"
else
  input_date="$1"
  echo "vuota"
fi


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
