#!/usr/bin/env bash

# SPDX-FileCopyrightText: Carlo Piana, Federico Edo Granata
#
# SPDX-License-Identifier: BSD-2-Clause

# shell script to convert date to another timezone
# usage: dated.sh [date]

# the script will load all the timezones with the following command
# timedatectl list-timezones
# the list of timezones is then parsed to group them by continent
# so the user can interactively select the continent and timezone

if [ -z "$1" ]; then
    utc_date=$(date +"%Y-%m-%d %T %Z")
else
    utc_date=$(date -u -d "$1" +"%Y-%m-%d %T %Z")
fi

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
                printf "+---------------------------------------------------------+ \n"
                printf "Universal Coordinated time: %s \n" \
                "$(date -d "$utc_date" +"%Y-%m-%d %T %Z" -u)"
                printf "+---------------------------------------------------------+ \n"

                printf "European Time: \t %s \n" "$(date -d "$utc_date" +"%Y-%m-%d %T %Z" )"
                export TZ=$TZ; printf "$loc:%*s$(date -d "$utc_date" +"%Y-%m-%d %T %Z") \n" \
                "$((16-${#loc}))"
                exit
            fi
        done
    fi
done
