#!/bin/bash

# processa tutti i file .p7m nella directory da cui lo script è generato e se
# non sono già estratti, estrae il file non firmato nella stessa directory 
# TODO passare una directory diversa da quella di esecuzione

#!/bin/bash

echo "Avvio processo per i file .p7m..."
echo "---------------------------------"

# Contatore per i file processati
contatore_processati=0

# Cicla su tutti i file con estensione .p7m nella directory corrente
for file_p7m in *.p7m; do
    
    # [Meccanismo di Sicurezza] Gestisce il caso in cui non ci siano file .p7m
    if [[ "$file_p7m" == "*.p7m" ]]; then
        echo "Nessun file .p7m trovato nella directory corrente."
        break  # Esci dal ciclo for
    fi
    
    # 1. Rimuove l'estensione .p7m per ottenere il nome del file di destinazione
    # Esempio: "documento.pdf.p7m" diventa "documento.pdf"
    nome_destinazione="${file_p7m%.*}"
    
    # 2. Controlla se il file di destinazione esiste già
    if [[ -e "$nome_destinazione" ]]; then
        # Il file esiste, salta al successivo (come richiesto)
        echo "SKIP: Il file di destinazione '$nome_destinazione' esiste già. Passaggio al successivo."
        continue  # Passa direttamente all'iterazione successiva del ciclo for
    else
        # 3. Il file di destinazione NON esiste, lo crea
        echo "estraggo '$nome_destinazione' dal file '$file_p7m'."
        
        # Estrae il file 
        /usr/bin/openssl smime -in "$file_p7m" -inform DER -verify -noverify -out "$nome_destinazione" ` `#o .txt || \
        echo "$file_p7m non contiene una firma valida"
        
        contatore_processati=$((contatore_processati + 1))
    fi
    
done

echo "---------------------------------"
echo "Processo completato. File creati/aggiornati: $contatore_processati"


# /usr/bin/openssl smime -in "$file_p7m" -inform DER -verify -noverify -out "$nome_destinazione" ` `#o .txt

