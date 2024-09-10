#!/bin/sh

BUILD_PREFIX="PixelWinch"

TEAM_ID="XXXXXXXXXX"
KEYCHAIN_PROFILE="<redacted>"

ZIP_TO="$HOME/Desktop"
UPLOAD_TO="<redacted>"
PUBLIC_URL="https://www.ricciadams.com/downloads/pixel-winch/betas"

# ----------------------------------

BUILD_STRING=""

show_notification ()
{
    osascript -e "display notification \"$1\" with title \"Archiving ${BUILD_STRING}\""
}

set_status ()
{
    THE_TIME=$(date +"%I:%M:%S %p")
    
    echo "# $BUILD_STRING"   > "${STATUS_MD}"
    echo                    >> "${STATUS_MD}"
    echo "\`$THE_TIME\`"    >> "${STATUS_MD}"
    echo "$1"               >> "${STATUS_MD}"
    
    if [[ -n "$2" ]]; then
        echo                    >> "${STATUS_MD}"
        echo "\`\`\`"           >> "${STATUS_MD}"
        echo "$2"               >> "${STATUS_MD}"
        echo "\`\`\`"           >> "${STATUS_MD}"
    fi
}

add_log ()
{
    echo $1 >> "${TMP_DIR}/log.txt"
}

get_plist_build ()
{
    printf $(defaults read "$1" CFBundleVersion | sed 's/\s//g' )
}

TMP_DIR=$(mktemp -d /tmp/"${BUILD_PREFIX}"-Archive.XXXXXX)
STATUS_MD="${TMP_DIR}/status.md"

# 1. Export archive to tmp location and set APP_FILE, push to parent directory
mkdir -p "${TMP_DIR}"
defaults write "${TMP_DIR}/options.plist" method developer-id
defaults write "${TMP_DIR}/options.plist" teamID "$TEAM_ID"

set_status "Exporting archive from Xcode."

xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportOptionsPlist "${TMP_DIR}/options.plist" -exportPath "${TMP_DIR}"

APP_FILE=$(find "${TMP_DIR}" -name "$FULL_PRODUCT_NAME" | head -1)

BUILD_NUMBER=$(get_plist_build "$APP_FILE"/Contents/Info.plist)
BUILD_STRING="${BUILD_PREFIX}-${BUILD_NUMBER}"
ZIP_FILE="${BUILD_STRING}.zip"

add_log "ARCHIVE_PATH = '$ARCHIVE_PATH'"
add_log "FULL_PRODUCT_NAME = '$FULL_PRODUCT_NAME'"
add_log "BUILD_NUMBER = '$BUILD_NUMBER'"
add_log "BUILD_STRING = '$BUILD_STRING'"
add_log "APP_FILE = '$APP_FILE'"

touch "$STATUS_MD"
open -b com.apple.dt.Xcode "$STATUS_MD"

pushd "$APP_FILE"/.. > /dev/null

# Zip up $APP_FILE to $ZIP_FILE and upload to notarization server

zip --symlinks -r "$ZIP_FILE" "$(basename "$APP_FILE")"

set_status "Sending to Apple notary service. This may take several minutes."

xcrun notarytool submit "$ZIP_FILE" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --output-format plist \
    --wait \
    1> "${TMP_DIR}/output-notarytool-submit.plist" \
    2> "${TMP_DIR}/output-notarytool-submit-err.txt"

SUBMIT_ID=$(    defaults read "${TMP_DIR}/output-notarytool-submit.plist" id)
SUBMIT_STATUS=$(defaults read "${TMP_DIR}/output-notarytool-submit.plist" status)
 
add_log "SUBMIT_ID = '$SUBMIT_ID'"
add_log "SUBMIT_STATUS = '$SUBMIT_STATUS'"

if [[ "${SUBMIT_STATUS}" =~ "Accepted" ]] ; then
    set_status "Stapling file."
    xcrun stapler staple "$APP_FILE"

    FINAL_ZIP_FILE="$ZIP_TO/$ZIP_FILE"
    zip --symlinks -r "$FINAL_ZIP_FILE" $(basename "$APP_FILE")
    scp "$FINAL_ZIP_FILE" "$UPLOAD_TO"

    if [ -n "$PUBLIC_URL" ]; then
        set_status "Uploaded '$ZIP_FILE' to server." "$PUBLIC_URL/$ZIP_FILE"
    else
        set_status "Uploaded '$ZIP_FILE' to server. **confetti**"
    fi

else 
    set_status "Received status of ${SUBMIT_STATUS}.\n\nFetching log."

    xcrun notarytool log "$SUBMIT_ID" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        1> "${TMP_DIR}/output-notarytool-log.txt" \
        2> "${TMP_DIR}/output-notarytool-log-err.txt"

    NOTARY_LOG=$(cat "${TMP_DIR}/output-notarytool-log.txt")
    
    set_status "Received status of ${SUBMIT_STATUS}." "$NOTARY_LOG"
fi

popd > /dev/null
