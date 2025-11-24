

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
    init_all_modules
    read_config
    parse_options "${@}"
}


climah_main() {
    climah_init "${@}"
    $command
}
