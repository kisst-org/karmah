

climah_init() {
    init_argparse
    init_logging "${@}"
    init_all_modules
}


climah_main() {
    climah_init "${@}"
    read_config
    parse_options "${@}"
    $command
}
