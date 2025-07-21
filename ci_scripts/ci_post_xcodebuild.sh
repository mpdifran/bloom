#!/usr/bin/env bash

#  ci_post_xcodebuild.sh
#
#  Created by Mark DiFranco on 2024-03-26.
#

set -e

if [[ -n $CI_ARCHIVE_PATH ]];
then
    echo "Found valid archive path."

    ls -al

    pushd $CI_ARCHIVE_PATH/dSYMs

    if [[ $CI_BUNDLE_ID == "com.lotus-labs.bloom" ]]; then
        echo "App is Bloom. Start uploading dSYMs to BugSnag."

        curl --http1.1 https://upload.bugsnag.com/ \
        -F apiKey=e24d7aa4dce2bddffd5e2db22c7ec9bd \
        -F dsym=@Bloom.app.dSYM/Contents/Resources/DWARF/Bloom \
        -F projectRoot=./

        echo "Finished uploading dSYMs"
    elif [[ $CI_BUNDLE_ID == "com.lotus-labs.gardener" ]]; then
        echo "App is Gardener. Start uploading dSYMs to BugSnag."

        curl --http1.1 https://upload.bugsnag.com/ \
        -F apiKey=98b5d461b2c6b0e63dd53acdd675ef26 \
        -F dsym=@Gardener.app.dSYM/Contents/Resources/DWARF/Gardener \
        -F projectRoot=./

        echo "Finished uploading dSYMs"
    else
        echo "App is not integrated with Bugnsag. Skipping dSYM upload."
    fi
fi
