#!/usr/bin/env bash
# Script Name: karmah
# Description: Kubernetes Assortment of Rendered MAnifests Helpers
# Author: Mark Hooijkaas
# Sourcecode: https://github.com/kisst-org/karmah/
# License: Apache License version 2.0
# Install or update to newest version with following command:
#   curl -OL https://raw.githubusercontent.com/kisst-org/karmah/refs/heads/main/karmah && chmod 755 karmah

if [ ${BASH_VERSINFO:-0} -lt 4 ]; then
    echo "bash version too old (3.x or older), please use a newer version"
    echo "if you are on MacOS you can use the following command"
    printf "  brew install bash\n"
    exit 1
fi

set -eu
shopt -s extglob
script_name="${0}"

main() { climah-main "${@}"; }
