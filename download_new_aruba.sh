#!/bin/bash

# Configuration
BASE_URL="https://updatesfirma.aruba.it/public_share/arubasign_standard"
FILENAME_PREFIX="ArubaSign(standard)-lin-x64-25"
EXT=".tar.bz2"

# Starting points (Adjust based on your last successful download)
MINOR=0
BUILD=1

if [ -n "$1" ]; then
    MINOR=$1
fi

if [ -n "$2" ]; then
    BUILD=$2
fi

echo "--- Ubuntu Mogul: Verbose Version Scanner ---"
echo "Targeting Base: $BASE_URL"
echo "---------------------------------------------"

while [ $MINOR -le 99 ]; do
    while [ $BUILD -le 99 ]; do
        # Format logic for 25.0.x vs 25.01.x
        if [ $MINOR -lt 1 ]; then
            VERSION="0.$BUILD"
        else
            VERSION="$(printf "%02d" $MINOR).$BUILD"
        fi

        FULL_URL="${BASE_URL}/${FILENAME_PREFIX}.${VERSION}${EXT}"
        
        # Display the specific URL being probed
        echo -n "Probing: $FULL_URL ... "
        
        # Perform the HEAD request and capture the HTTP status code
        HTTP_STATUS=$(curl --silent --head --output /dev/null --write-out "%{http_code}" "$FULL_URL")

        if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "[200 OK]"
            echo "---------------------------------------------"
            echo "MATCH FOUND! Downloading $VERSION..."
            wget -P ~/Downloads/ "$FULL_URL"
            exit 0
        elif [ "$HTTP_STATUS" -eq 404 ]; then
            echo "[404]"
        else
            echo "[HTTP $HTTP_STATUS]"
        fi

        BUILD=$((BUILD + 1))

        sleep 0.5
    done
    
    # Reset build to 0 and move to next minor version
    BUILD=0
    MINOR=$((MINOR + 1))
done

echo "Search complete. No new files found up to minor version 99."
