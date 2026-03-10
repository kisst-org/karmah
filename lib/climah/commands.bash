
init_climah_vars_commands() {
    declare -g command
    declare -gA command_function=()
    declare -gA command_alias=()
}

init_climah_module_commands() {
    help-add-topic cmd commands show-commands "show available commands"
}

parse-command() {
    if [[ ! -z ${command:-} ]]; then
        debug overriding current command $command with $name
    fi
    name=${command_alias[$1]:-$1}
    command=$name
}

add-command() {
    local short=$1 name=$2 func=${3:-run-command-$name} summary=${4:-no summary}
    parse_arg_func[$name]=parse-command
    if [[ ${enable_short_commands:-true} && ! -z $short ]]; then
        local s
        for s in ${short//,/ }; do
            arg_alias[$s]=$name
            command_alias[$s]=$name
        done
    fi
    help-add-item command "$short" $name "" "$summary"
    command_function[$name]=$func
}

show-commands() { help-list-items command; }

run-command() { ${command_function[$command]}; }
