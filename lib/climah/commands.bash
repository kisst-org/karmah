
commands::declare-vars() {
    declare -g command_to_run=""
    declare -g default_command
    declare -gA command_function=()
    declare -gA command_params=()
    declare -gA command_alias=()
}
commands::init-module() {
    append-argparse-func parse-if-command
}

commands-show-help() { list-help-items command; }

parse-if-command() {
    local name=$1
    if [[ -z ${command_function[$name]:-} ]]; then  return 0; fi
    if [[ ! -z ${command_to_run:-} ]]; then
        log-warn command "overriding current command $command_to_run with $name"
    fi
    command_to_run=$name
    argparse_parse_count=1
}

add-command() {
    local short=$1 name=$2
    local func=${3:-run-command-$name} summary=${4:-no summary}
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    command_function[$name]=$func
    command_params[$name]=$name
    add-help-item $name command:$name "" "$summary"
}

run-active-command() {
    local command=${command_to_run:-$default_command}
    ${command_function[$command]} ${command_params[$command]}
}
