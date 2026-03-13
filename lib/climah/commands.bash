
commands-init-climah-vars() {
    declare -g command
    declare -gA command_function=()
    declare -gA command_alias=()
}

commands-init-climah-module() {
    help-add-topic cmd commands "" "show available commands"
}
commands-show-help() { help-list-items command; }

commands-parse() {
    local name=$argparse_params
    if [[ ! -z ${command:-} ]]; then
        debug overriding current command $command with $name
    fi
    command=$name
}

commands-add() {
    local short=$1 name=$2 func=${3:-run-command-$name} summary=${4:-no summary} cmd
    for cmd in $name $short; do
        argparse_arg_func[$cmd]=commands-parse
        argparse_arg_params[$cmd]=$name
    done
    help-add-item command "$short" $name "" "$summary"
    command_function[$name]=$func
}

commands-run() { ${command_function[$command]}; }
