#!/usr/bin/env bash
# Script Name: karmah
# Description: Kubernetes Assortment of Rendered MAnifests Helpers
# Author: Mark Hooijkaas
# Sourcecode: https://github.com/kisst-org/karmah/
# License: Apache License version 2.0
# Install or update to newest version with following command:
#   curl -OL https://raw.githubusercontent.com/kisst-org/karmah/refs/heads/main/karmah && chmod 755 karmah

set -eu
shopt -s extglob
script_name="${0}"

main() {
    init_argparse
    init_logging "${@}"
    init_all_modules
    read_config
    parse_options "${@}"
    $command
}
