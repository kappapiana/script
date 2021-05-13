#!/usr/bin/env bash

# simple oneliner to convert date in various time zones

set -e  # fails on error

utc_date=$(date -d "$1" +"%Y-%m-%d %T %Z")

TZs=(
  'America/Los_Angeles'
  'America/New_York'
  'Asia/Tokyo'
  'Australia/Sydney'
  'Europe/London'
  'Europe/Dublin'
  'Europe/Moscow'
)


printf "+---------------------------------------------------------+ \n"
printf "Universal Coordinated time: $(date -d "$utc_date" +"%Y-%m-%d %T %Z" -u) \n"
printf "+---------------------------------------------------------+ \n"

printf "European Time: \t $(date -d "$utc_date" +"%Y-%m-%d %T %Z" ) \n"

for TZ in "${TZs[@]}"
do
  loc=$(echo $TZ | cut -f 2 -d / | tr '_' ' ')
  TZ=$TZ ; printf "$loc:%*s$(date -d "$utc_date" +"%Y-%m-%d %T %Z") \n" "$((16-${#loc}))"
done