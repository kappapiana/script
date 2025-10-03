#!/bin/bash

# Si aspetta di trovare un file .p7m passato come argomento
# Scrive, nella stessa directory, il file non firmato

# Controlla se il file passato come argomento termina con .p7m
nomefile="$1"
if [[ "$1" == *.p7m ]] ; then 
    nomefile_noext="${nomefile%.*}"
    echo "$nomefile_noext" ; else 
    echo "not p7m, script interrotto"
    exit 1; 
fi

# Estrae il file 
/usr/bin/openssl smime -in "$nomefile" -inform DER -verify -noverify -out "$nomefile_noext" ` `#o .txt

