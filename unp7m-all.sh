#!/bin/bash

# processa tutti i file .p7m nella directory da cui lo script è generato
# e se non sono già estratti, estrae il file non firmato.

echo "Avvio processo per i file .p7m..."
echo "---------------------------------"

# Contatore per i file processati con successo
contatore_processati=0

# Cicla su tutti i file con estensione .p7m nella directory corrente
for file_p7m in *.p7m; do
    
    # [Meccanismo di Sicurezza] Gestisce il caso in cui non ci siano file .p7m
    if [[ "$file_p7m" == "*.p7m" ]]; then
        echo "Nessun file .p7m trovato nella directory corrente."
        break
    fi
    
    # 1. Rimuove l'estensione .p7m per ottenere il nome del file di destinazione
    nome_destinazione="${file_p7m%.*}"
    
    echo "  - Analizzo il file: $file_p7m"
    
    # 2. Controlla se il file di destinazione esiste già
    if [[ -e "$nome_destinazione" ]]; then
        echo "  SKIP: Il file di destinazione '$nome_destinazione' esiste già."
        continue
    fi

    # 3. Il file di destinazione NON esiste, lo estrae con openssl e gestisce il risultato
    
    # Esegui openssl:
    # - `2> /dev/null` sopprime l'output di errore standard (es. problemi di firma, certificati non trovati)
    # - `&&` (Successo)
    # - `||` (Fallimento)
    /usr/bin/openssl smime -in "$file_p7m" -inform DER -verify -noverify -out "$nome_destinazione" 2> /dev/null \
    && {
        # Blocco di SUCCESSO (openssl ha restituito 0)
        echo "  SUCCESSO: Estratto in '$nome_destinazione'."
        contatore_processati=$((contatore_processati + 1))
    } \
    || {
        # Blocco di ERRORE (openssl ha restituito != 0)
        echo "  ERRORE: Impossibile estrarre '$file_p7m'. Non contiene una firma valida o è danneggiato."
        # Pulisci: openssl potrebbe aver creato un file parziale in caso di errore
        if [[ -f "$nome_destinazione" ]]; then
            rm -f "$nome_destinazione"
            echo "  PULIZIA: Rimosso file di output incompleto '$nome_destinazione'."
        fi
    }
    
done

echo "---------------------------------"
echo "Processo completato. File estratti con successo: $contatore_processati"