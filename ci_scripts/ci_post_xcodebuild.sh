#!/usr/bin/env bash

#  ci_post_xcodebuild.sh
#  Picasso
#
#  Created by Mark DiFranco on 2024-03-26.
#

set -e

if [[ -n $CI_ARCHIVE_PATH ]];
then
    echo "Found valid archive path."

    pushd $CI_ARCHIVE_PATH/dSYMs

    if [[ $CI_BUNDLE_ID == "com.lotus-labs.bloom" ]]; then
        echo "App is Bloom. Start uploading dSYMs to BugSnag."

        curl --http1.1 https://upload.bugsnag.com/ \
        -F apiKey=bdabfb744461469374c2cc273b493168 \
        -F dsym=@Supplements.app.dSYM/Contents/Resources/DWARF/Supplements \
        -F projectRoot=./

        echo "Finished uploading dSYMs"
    else
        echo "App is not Bloom. Skipping dSYM upload."
    fi
fi
