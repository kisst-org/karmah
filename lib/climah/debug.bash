
debug::init-module() {
    append-argparse-func parse-if-debug-option
    help_level=expert
    # TODO add as normal options for help???
}


parse-pre-init-debug() {
    declare -g debug_init_phase=true
    for arg in "$@"; do
        parse-if-debug-option $arg
    done
    log-debug logger "root log-level ${logger_config[level]:-unknown}"
    unset debug_init_phase
}

_set-init-debug-level() {
    argparse_parse_count=1
    # ignore if not in init phase
    if ${debug_init_phase:-false}; then
        logger_config[level]=$1;
        log-info debug "setting log level for init-phase to ${logger_config[level]}"
    fi
}

parse-if-debug-option() {
    case $1 in
        --debug-init-verbose) _set-init-debug-level verbose;;
        --debug-init-debug)   _set-init-debug-level debug;;
        --debug-init-trace)   _set-init-debug-level trace;;
    esac
}
