#!/bin/bash

# usage: sh scripts/bash/deeplink.sh "https://domain.com"

adb shell 'am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "'"${1:-template://profile/d67b27a0-dbd1-47ba-81bb-783b17f9f86c}"'"' \
    az.theternal.template