

climah-init() {
    init-logging "${@}"
    init-all-modules # TODO: ordering: help logging options render git
    read-config
    if [[ $# == 0 ]]; then
        printf "no arguments passed, pass at least one path or command\n\n"
        show-short-help
        exit 1
    else
        argparse-parse-arguments "${@}"
    fi
}

climah-main() {
    declare -g climah_prog_name=$(basename $0)
    declare -g climah_prog
    declare -g climah_help_full_function
    climah-init "${@}"
    commands-run
}
