#!/usr/bin/env bash

#  ci_post_xcodebuild.sh
#
#  Created by Mark DiFranco on 2024-03-26.
#

set -e

if [[ -n $CI_ARCHIVE_PATH ]];
then
    echo "Found valid archive path."

    pushd $CI_ARCHIVE_PATH/dSYMs

    # BugSnag API keys are provided via Xcode Cloud environment variables.
    if [[ $CI_BUNDLE_ID == "com.lotus-labs.bloom" && -n $BUGSNAG_API_KEY_BLOOM ]]; then
        echo "App is Bloom. Start uploading dSYMs to BugSnag."

        curl --http1.1 https://upload.bugsnag.com/ \
        -F apiKey=$BUGSNAG_API_KEY_BLOOM \
        -F dsym=@Bloom.app.dSYM/Contents/Resources/DWARF/Bloom \
        -F projectRoot=./

        echo "Finished uploading dSYMs"
    elif [[ $CI_BUNDLE_ID == "com.lotus-labs.gardener" && -n $BUGSNAG_API_KEY_GARDENER ]]; then
        echo "App is Gardener. Start uploading dSYMs to BugSnag."

        curl --http1.1 https://upload.bugsnag.com/ \
        -F apiKey=$BUGSNAG_API_KEY_GARDENER \
        -F dsym=@Gardener.app.dSYM/Contents/Resources/DWARF/Gardener \
        -F projectRoot=./

        echo "Finished uploading dSYMs"
    else
        echo "No BugSnag API key configured for $CI_BUNDLE_ID. Skipping dSYM upload."
    fi
fi
