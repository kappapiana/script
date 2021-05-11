#!/usr/bin/env bash

# simple oneliner to convert date in various time zones

set -e  # fails on error

utc_date=$(date -d "$1" +"%Y-%m-%d %T %Z")


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
