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
printf "Universal Coordinated time: %s \n" \
"$(date -d "$utc_date" +"%Y-%m-%d %T %Z" -u)"
printf "+---------------------------------------------------------+ \n"

printf "European Time: \t %s \n" "$(date -d "$utc_date" +"%Y-%m-%d %T %Z" )"

for TZ in "${TZs[@]}"
do
  loc=$(echo "$TZ" | cut -f 2 -d / | tr '_' ' ')
  export TZ=$TZ ; printf "$loc:%*s$(date -d "$utc_date" +"%Y-%m-%d %T %Z") \n" \
  "$((16-${#loc}))"
done
