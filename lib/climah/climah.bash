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
        logger_level=([root]=info) # reset all loglevels, from pre-init
        argparse-parse-arguments "${@}"
    fi
}

climah-main() {
    declare -g climah_prog_name=$(basename $0)
    declare -g climah_prog_path="$0"
    climah-init "${@}"
    commands-run
}

load-libraries() {
    for file in ${lib_dir:-lib}/*.bash; do
        source $file
    done
}
