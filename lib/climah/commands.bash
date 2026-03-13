
commands-init-climah-vars() {
    declare -g command
    declare -gA command_function=()
    declare -gA command_alias=()
}

commands-init-climah-module() {
    help-add-topic cmd commands show-commands "show available commands"
}

parse-command() {
    local name=$argparse_params
    if [[ ! -z ${command:-} ]]; then
        debug overriding current command $command with $name
    fi
    command=$name
}

add-command() {
    local short=$1 name=$2 func=${3:-run-command-$name} summary=${4:-no summary} cmd
    for cmd in $name $short; do
        argparse_arg_func[$cmd]=parse-command
        argparse_arg_params[$cmd]=$name
    done
    help-add-item command "$short" $name "" "$summary"
    command_function[$name]=$func
}

show-commands() { help-list-items command; }

run-command() { ${command_function[$command]}; }
