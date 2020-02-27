#!/bin/bash

file=$1

echo "Start!" da file $file

rm /home/carlo/white.txt

#find those whiltelisted, never shut them off
sudo iptables --list INPUT -v -n | grep ^\ *[0-9].*ACCEPT | awk '{print $8}' > /home/carlo/white.txt

cat /home/carlo/white.txt

sleep 1

rm /home/carlo/present.txt

#find those already in the REJECT list

sudo /sbin/iptables --list -n --line-numbers | egrep "(REJECT) | (DROP)"  | awk '{print $5}' | sort -n | uniq > /home/carlo/present.txt

sleep 1

echo "iniziamo while"

while read p; do

	if grep -q "$p" /home/carlo/present.txt ; then
		echo "trovato $p"
	elif grep -q "$p" /home/carlo/white.txt ; then
		echo "trovato e buono $p"
	else
		echo "$p non trovato"
	echo "comando: sudo iptables -I INPUT -s $p -j DROP"
	sudo iptables -I INPUT -s $p -j DROP

		echo "$p cancellato" 
	fi 

done < $1

sudo bash -c "iptables-save > /etc/network/iptables.save"

