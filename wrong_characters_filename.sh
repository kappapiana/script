#!/bin/bash



file=`echo "$(dirname -- "$0")/substitutions.txt"`

echo $file

ls "$1"

echo "+++"

pwd

echo "+++"

rename 's/[(]|[)]/‒/g' "$1" #strips brackets first

rename 's/[\ ]/_/g' "$1" #strips whitespace


while read line;

do

# echo $line

  trans=`echo $line | awk --field-separator "-" '{print $2}' `

  origin=`echo $line | awk --field-separator "-" '{print $1}' `

 # echo "$origin"

  rename s/"$origin"/"$trans"/g "$1"

done <"$file"
