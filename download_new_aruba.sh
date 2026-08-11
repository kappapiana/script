#!/bin/bash

# Configuration
BASE_URL="https://updatesfirma.aruba.it/public_share/arubasign_standard"
FILENAME_PREFIX="ArubaSign(standard)-lin-x64-25"
EXT=".tar.bz2"

# Starting points (Adjust based on your last successful download)
MINOR=0
BUILD=1
DOWNLOAD_DIR="${HOME}/Downloads"

if [ -n "$1" ]; then
    MINOR=$1
fi

if [ -n "$2" ]; then
    BUILD=$2
fi

ATTEMPTS=0
while [ ! -d "$DOWNLOAD_DIR" ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ "$ATTEMPTS" -gt 4 ]; then
        echo "this ain't working"
        exit 1
    fi
    echo "Download directory does not exist: $DOWNLOAD_DIR"
    read -r -p "Enter a different download directory: " DOWNLOAD_DIR
    # Expand ~ if the user typed it literally
    DOWNLOAD_DIR="${DOWNLOAD_DIR/#\~/$HOME}"
done

echo "--- Ubuntu Mogul: Verbose Version Scanner ---"
echo "Targeting Base: $BASE_URL"
echo "Download dir: $DOWNLOAD_DIR"
echo "---------------------------------------------"

LAST_FOUND_URL=""
LAST_FOUND_VERSION=""
LOOKAHEAD=0

download_last() {
    echo "---------------------------------------------"
    echo "Downloading $LAST_FOUND_VERSION..."
    wget -P "$DOWNLOAD_DIR" "$LAST_FOUND_URL"
    exit 0
}

ask_after_lookahead() {
    while true; do
        read -r -p "No newer build in the last 10. Look 10+ more, or download $LAST_FOUND_VERSION? [10/d]: " choice
        case "$choice" in
            10)
                LOOKAHEAD=10
                echo "Looking 10 more builds ahead..."
                return
                ;;
            d|D)
                download_last
                ;;
            *)
                echo "Enter 10 or d"
                ;;
        esac
    done
}

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
            echo "MATCH FOUND: $VERSION"
            LAST_FOUND_URL="$FULL_URL"
            LAST_FOUND_VERSION="$VERSION"
            LOOKAHEAD=0
            read -r -p "Attempt finding 10+ builds? [y/N]: " continue_search
            case "$continue_search" in
                y|Y)
                    LOOKAHEAD=10
                    echo "Looking 10 more builds ahead..."
                    ;;
                *)
                    download_last
                    ;;
            esac
        elif [ "$HTTP_STATUS" -eq 404 ]; then
            echo "[404]"
        else
            echo "[HTTP $HTTP_STATUS]"
        fi

        if [ "$HTTP_STATUS" -ne 200 ] && [ "$LOOKAHEAD" -gt 0 ]; then
            LOOKAHEAD=$((LOOKAHEAD - 1))
            if [ "$LOOKAHEAD" -eq 0 ]; then
                ask_after_lookahead
            fi
        fi

        BUILD=$((BUILD + 1))

        sleep 0.5
    done
    
    # Reset build to 0 and move to next minor version
    BUILD=0
    MINOR=$((MINOR + 1))
done

if [ -n "$LAST_FOUND_URL" ]; then
    echo "Search limit reached."
    download_last
fi

echo "Search complete. No new files found up to minor version 99."
