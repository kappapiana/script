#!/bin/bash

find . -type f -name "*.od*" | while read -r i ; do
   [ "$1" ] || { echo "You forgot search string!" ; exit 1 ; }
      unzip -ca "$i" 2>/dev/null | if grep -iq "$*" ; then
         
		       echo "string found in $i" | nl
	          fi
	  done
