#!/bin/sh

TEAM_ID="XXXXXXXXXX"

APP_NAME="Pixel Winch"

NOTARY_BUNDLE_ID="com.iccir.PixelWinch"
NOTARY_APPLE_ID="<redacted>"
NOTARY_ASC_PROVIDER="RicciAdams1115211120"
NOTARY_PASSWORD="<redacted>"

ZIP_TO="$HOME/Desktop"
UPLOAD_TO="<redacted>"
BUILD_STRING=""

# ----------------------------------

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

TMP_DIR=`mktemp -d /tmp/Embrace-Archive.XXXXXX`
STATUS_MD="${TMP_DIR}/status.md"

# 1. Export archive to tmp location and set APP_FILE, push to parent directory
mkdir -p "${TMP_DIR}"
defaults write "${TMP_DIR}/options.plist" method developer-id
defaults write "${TMP_DIR}/options.plist" teamID "$TEAM_ID"

set_status "Exporting archive from Xcode."

xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportOptionsPlist "${TMP_DIR}/options.plist" -exportPath "${TMP_DIR}"

APP_FILE=$(find "${TMP_DIR}" -name "$FULL_PRODUCT_NAME" | head -1)

BUILD_NUMBER=$(get_plist_build "$APP_FILE"/Contents/Info.plist)
BUILD_STRING="${APP_NAME}-${BUILD_NUMBER}"

add_log "ARCHIVE_PATH = '$ARCHIVE_PATH'"
add_log "FULL_PRODUCT_NAME = '$FULL_PRODUCT_NAME'"
add_log "BUILD_NUMBER = '$BUILD_NUMBER'"
add_log "BUILD_STRING = '$BUILD_STRING'"
add_log "APP_FILE = '$APP_FILE'"

touch "$STATUS_MD"
open -b com.apple.dt.Xcode "$STATUS_MD"

pushd "$APP_FILE"/.. > /dev/null


# 2. Zip up $APP_FILE to "App.zip" and upload to notarization server

zip --symlinks -r App.zip $(basename "$APP_FILE")

set_status "Sending to Apple notary service. This may take several minutes."

xcrun altool \
    --notarize-app --file App.zip --type osx \
    --primary-bundle-id "$NOTARY_BUNDLE_ID" \
    --username "$NOTARY_APPLE_ID" \
    --password "$NOTARY_PASSWORD" \
    --asc-provider "$NOTARY_ASC_PROVIDER" \
    > "${TMP_DIR}/output-notarize-app.txt" 2>&1 

NOTARY_UUID=$(grep RequestUUID "${TMP_DIR}/output-notarize-app.txt" | awk '{print $3}')

add_log "NOTARY_UUID = '$NOTARY_UUID'"

# 3. Wait for notarization

NOTARY_SUCCESS=0

set_status "Finished sending to Apple notary service"

while true
do
    NOTARY_OUTPUT=$(
        xcrun altool \
        --notarization-info "${NOTARY_UUID}" \
        --username "$NOTARY_APPLE_ID" \
        --password "$NOTARY_PASSWORD" \
        2>&1
    )

    if [ $? -ne 0 ]; then
        add_log "altool --notarization-info returned $?"
    fi

    add_log "${NOTARY_OUTPUT}"
    set_status "Waiting for notary response." "${NOTARY_OUTPUT}"
    
    if [[ "${NOTARY_OUTPUT}" =~ "Invalid" ]] ; then
        add_log "altool --notarization-info results invalid"
        break
    fi

    if [[ "${NOTARY_OUTPUT}" =~ "success" ]]; then
        NOTARY_SUCCESS=1
        break
    fi

    sleep 2
done


# 4. Staple

if [ $NOTARY_SUCCESS -eq 1 ] ; then
    set_status "Stapling file."
    xcrun stapler staple "$APP_FILE"
    
else
    set_status "Error during notarization."
fi

# 5. Re-zip file and upload

if [ $NOTARY_SUCCESS -eq 1 ] ; then
    FINAL_ZIP_FILE="$ZIP_TO/$BUILD_STRING".zip
    zip --symlinks -r "$FINAL_ZIP_FILE" $(basename "$APP_FILE")
    scp "$FINAL_ZIP_FILE" "$UPLOAD_TO"

    set_status "Uploaded '$BUILD_STRING.zip' to server. **confetti**"
fi

popd > /dev/null
