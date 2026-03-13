
commands-init-climah-vars() {
    declare -g command
    declare -g default_command
    declare -gA command_function=()
    declare -gA command_params=()
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

commands-register-func() {
    local short=$1 name=$2 func=${3:-run-command-$name} params=${4:-} cmd
    for cmd in $name $short; do
        argparse_arg_func[$cmd]=commands-parse
        argparse_arg_params[$cmd]=$params
    done
    command_function[$name]=$func
    command_params[$name]=$params
}
commands-add() {
    local short=$1 name=$2 func=${3:-run-command-$name} summary=${4:-no summary}
    commands-register-func $short $name $func $name
    help-add-item command "$short" $name "" "$summary"
}

commands-run() {
    : ${command:=$default_command}
    ${command_function[$command]} ${command_params[$command]}
}
