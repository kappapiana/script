#!/bin/bash

# takes a list of bad IPs and after checking against whitelist
# blocks them
# list is provided as argument to the command
# requires sudo and password insertion

# **************************************************

# caution: can lock you out, make sure you are whiltelisted!

# **************************************************

file=$1

echo "Start! da file $1"

rm ~/white.txt

#find those whiltelisted, never shut them off

sudo iptables --list INPUT -v -n | grep ^\ *[0-9].*ACCEPT | awk '{print $8}' > /home/carlo/white.txt

echo "these are whitelisted"
cat ~/white.txt

sleep 1

rm ~/present.txt

#find those already in the REJECT list

sudo /sbin/iptables --list -n --line-numbers | egrep "(REJECT) | (DROP)"  | awk '{print $5}' | sort -n | uniq > ~/present.txt

sleep 1

while read p; do

	if grep -q "$p" ~/present.txt ; then
		echo "trovato $p"
	elif grep -q "$p" ~/white.txt ; then
		echo "trovato e buono $p"
	else
		echo "$p non trovato"
	echo "comando: sudo iptables -I INPUT -s $p -j DROP"
	sudo iptables -I INPUT -s $p -j DROP

		echo "$p cancellato" 
	fi 

done < $1

sudo bash -c "iptables-save > /etc/network/iptables.save"

