

check-bash-version() {
    if [[ ${BASH_VERSINFO:-0} -lt 4 ]]; then
        echo "bash version too old (3.x or older), please use a newer version"
        echo "if you are on MacOS you can use the following command"
        printf "  brew install bash\n"
        exit 1
    fi
}

climah-init() {
    check-bash-version
    init-logging "${@}"
    module-init-all # TODO: ordering: help logging options render git
    read-config
    if [[ $# == 0 ]]; then
        printf "no arguments passed, pass at least one path or command\n\n"
        help-show-summary
        exit 1
    else
        parse-arguments "${@}"
    fi
}


climah-main() {
    declare -g climah_prog_name=$(basename $0)
    declare -g climah_prog
    declare -g climah_help_full_function
    climah-init "${@}"
    run-command
}
