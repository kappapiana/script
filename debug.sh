#!/bin/bash
echo "comparing hash list with the output of sha256sum..."
result=`diff --strip-trailing-cr <(cd messages; sha256sum * | awk '{print $1}' | sort; cd ..) <(cat hash_list.txt)`
if [ "$result" == "" ]; then echo "passed!"; else echo "error!"; fi

# a few variables that we need
today_date=`/bin/date +"%Y-%m-%d"`
oldest_date=`ls messages/ | awk --field-separator=- '{print $1}' |sort -n | head -n 1 | sed -e 's/\([0-9]\{4\}\)\([0-9]\{2\}\)/\1-\2-/'`

echo "your pec is: "
read pec

echo "your name is: "
read name

echo "your tax code is: "
read tax_code

# now ready to start working with the file

echo "" > dichiarazione_conservazione.txt #cleans the file

# DON'T TOUCH THE FILE BEFORE HERE

echo "Il sottoscritto Avv. $name, CF $tax_code attesta il corretto " >> dichiarazione_conservazione.txt
echo "svolgimento del procedimento di conservazione dei seguenti file in formato " >> dichiarazione_conservazione.txt
echo ".eml identificati tramite impronta hash sha256:" >> dichiarazione_conservazione.txt
echo "" >> dichiarazione_conservazione.txt


cat hash_list.txt >> dichiarazione_conservazione.txt #includes the hash_list file

echo "" >> dichiarazione_conservazione.txt
echo "Detti file costituiscono il contenuto della casella di posta elettronica" >> dichiarazione_conservazione.txt
echo "certificata $pec (messaggi ricevuti) dal giorno $oldest_date sino al " >> dichiarazione_conservazione.txt
echo "giorno $today_date." >> dichiarazione_conservazione.txt
echo "" >> dichiarazione_conservazione.txt
echo "L'elenco dei nomi dei file corrispondenti a tali impronte hash viene custodito" >> dichiarazione_conservazione.txt
echo "separatamente ai fini di facile rintraccio del singolo file." >> dichiarazione_conservazione.txt
echo "" >> dichiarazione_conservazione.txt
echo "Milano, $today_date" >> dichiarazione_conservazione.txt
echo "" >> dichiarazione_conservazione.txt
echo "Firmato digitalmente" >> dichiarazione_conservazione.txt
echo "" >> dichiarazione_conservazione.txt
echo "$name" >> dichiarazione_conservazione.txt
