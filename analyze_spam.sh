#!/bin/bash

# filters mail.log to find blocked spam, per recipient

# mail log has already been put in /tmp

spam_dir=/tmp/spam
spamlog=$spam_dir/spamlog.txt
spam_rec=$spam_dir/recipients.txt

mkdir $spam_dir 2>/dev/null
rm $spam_dir/* #clean all files made in previous runs

grep "Blocked SPAM" $1 > $spamlog

awk '{print $14}' $spamlog | sort | uniq  > $spam_rec

  while read line;

  do

    namefile=`echo $line | sed -E 's@[<|>|,]@@g'`

    grep "$line" $spamlog | awk '{print $12, $13, $14}'>> $spam_dir/$namefile.txt

  done <"$spam_rec"

echo "Your spammed out addresses are now in $spam_dir, separated by recpient(s)"
