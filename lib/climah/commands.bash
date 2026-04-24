
commands::declare-vars() {
    declare -g command_to_run=""
    declare -g default_command
    declare -gA command_function=()
    declare -gA command_params=()
    declare -gA command_alias=()
}

commands-show-help() { list-help-items command; }

commands-parse() {
    local name=${argparse_param_list[0]}
    if [[ ! -z ${command_to_run:-} ]]; then
        debug overriding current command $command_to_run with $name
    fi
    command_to_run=$name
}

commands-add() {
    local short=$1 name=$2
    local func=${3:-run-command-$name} summary=${4:-no summary}
    argparse_parse_func_map[$name]=commands-parse
    argparse_parse_params[$name]=$name
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    command_function[$name]=$func
    command_params[$name]=$name
    add-help-item command $name "" "$summary"
}

commands-run() {
    local command=${command_to_run:-$default_command}
    ${command_function[$command]} ${command_params[$command]}
}
