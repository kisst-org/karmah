climah-init() {
    init-logging "${@}" # TODO: deprecated remove with logging module
    init-loggers
    parse-pre-init-loglevels "${@}"
    load-libraries
    declare-all-module-vars
    init-all-modules # TODO: ordering: help logging options render git
    module=commands add-help-topic cmd command "" "show available commands"
    module=options  add-help-topic opt option  "" "show available options"
    module=modules  add-help-topic mod module  modules-show "show all modules"

    read-config
    if [[ $# == 0 ]]; then
        printf "no arguments passed, pass at least one path or command\n\n"
        show-short-help
        exit 1
    else
        logger_config[level]=info # reset root loglevels, from pre-init
        argparse-parse-arguments "${@}"
    fi
}

climah-main() {
    declare -g climah_prog_name=$(basename $0)
    declare -g climah_prog_path="$0"
    climah-init "${@}"
    run-active-command
}

load-lib-config() {
    if [[ -f lib/config ]]; then
        log-debug lib "loading initial config lib/config"
        source lib/config
    fi
}

load-libraries() {
    load-lib-config
    local dir; for dir in ${lib_dirs:-lib}; do
        local file; for file in ${dir}/*.bash; do
            log-debug lib "loading library $file"
            source $file
        done
    done
}

read-config() {
    if [[ -d config.d ]] && "${use_config_d:-true}"; then
        for file in config.d/*.config; do
            source $file
        done
    fi
}
