

check_bash_version() {
    if [[ ${BASH_VERSINFO:-0} -lt 4 ]]; then
        echo "bash version too old (3.x or older), please use a newer version"
        echo "if you are on MacOS you can use the following command"
        printf "  brew install bash\n"
        exit 1
    fi
}

climah_init() {
    check_bash_version
    init_logging "${@}"
    init_all_modules help logging options render git
    read_config
    if [[ $# == 0 ]]; then
        printf "no arguments passed, pass at least one path or command\n\n"
        help-show-summary
        exit 1
    else
        parse-arguments "${@}"
    fi
}


climah_main() {
    declare -g climah_prog_name=$(basename $0)
    declare -g climah_prog
    declare -g climah_help_full_function
    climah_init "${@}"
    run-command
}
