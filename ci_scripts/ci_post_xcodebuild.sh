#!/usr/bin/env bash

#  ci_post_xcodebuild.sh
#
#  Created by Mark DiFranco on 2024-03-26.
#

set -e

if [[ $CI_BUNDLE_ID == "com.lotus-labs.bloom" ]]; then
  bugsnag-cli upload xcode-build "$CI_PROJECT_PATH/Bloom.xcodeproj"
elif [[ $CI_BUNDLE_ID == "com.lotus-labs.gardener" ]]; then
  bugsnag-cli upload xcode-build "$CI_PROJECT_PATH/Gardener.xcodeproj"
else
  echo "App is not integrated with Bugsnag. Skipping dSYM upload."
fi

#if [[ -n $CI_ARCHIVE_PATH ]];
#then
#    echo "Found valid archive path."
#
#    pushd $CI_ARCHIVE_PATH/dSYMs
#
#    if [[ $CI_BUNDLE_ID == "com.lotus-labs.bloom" ]]; then
#        echo "App is Bloom. Start uploading dSYMs to BugSnag."
#
#        curl --http1.1 https://upload.bugsnag.com/ \
#        -F apiKey=e24d7aa4dce2bddffd5e2db22c7ec9bd \
#        -F dsym=@Bloom.app.dSYM/Contents/Resources/DWARF/Bloom \
#        -F projectRoot=./
#
#        echo "Finished uploading dSYMs"
#    else
#        echo "App is not Bloom. Skipping dSYM upload."
#    fi
#fi
