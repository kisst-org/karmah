

climah_init() {
    init_logging "${@}"
    init_all_modules
    read_config
    parse_options "${@}"
}


climah_main() {
    climah_init "${@}"
    $command
}
