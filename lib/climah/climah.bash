climah-init() {
    declare -g climah_prog_name=$(basename $0)
    declare -g climah_prog_path="$0"
    init-loggers
    parse-pre-init-debug "${@}"
    load-libraries
    declare-all-module-vars
    init-all-modules # TODO: ordering: help logging options render git
    module=commands add-help-topic cmd command "show available commands"
    module=options  add-help-topic opt option  "show available options"
    module=modules  add-help-topic mod module  "show all modules"
    read-config
}

climah-parse-args() {
    if [[ $# == 0 ]]; then
        printf "no arguments passed, pass at least one path or command\n\n"
        show-short-help
        exit 1
    fi
    logger_config[level]=info # reset root loglevels, from pre-init-debug
    argparse-parse-arguments "${@}"
}

climah-run() {
    run-active-command
    ${climah_wait_for_jobs:-}
}

load-lib-config() {
    local file=${CLIMAH_LIB_CONFIG:-lib/config}
    if [[ -f $file ]]; then
        log-debug climah "loading lib config file $file"
        source $file
    elif [[ ! -z ${CLIMAH_LIB_CONFIG:-} ]]; then
        log-error climah "lib config file CLIMAH_LIB_CONFIG=$file not found, exiting"
        exit 1
    else
        log-debug climah "defaul lib config file $file does not exist"
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
