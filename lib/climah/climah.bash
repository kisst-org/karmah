climah-init() {
    if [[ -f .climah.config ]]; then # TODO other name?
        source .climah.config
    fi
    init-logging "${@}"
    declare-all-module-vars
    load-libraries
    init-all-modules # TODO: ordering: help logging options render git
    module=commands add-help-topic cmd commands "" "show available commands"
    module=options  add-help-topic opt options  "" "show available commands"
    module=modules  add-help-topic mod modules  modules-show "show all modules"

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

load-libraries() {
    for file in ${lib_dir:-lib}/*.bash; do
        source $file
    done
}
