
init_climah_vars_commands() {
    declare -g command
    declare -g all_commands=""
    declare -gA command_function=()
    declare -gA command_module=()
    declare -gA command_short=()
    declare -gA command_level=()
    declare -gA command_alias=()
    declare -gA command_help=()
}

init_climah_module_commands() {
    add-help-subject ""  commands show-commands "show available commands"
}

parse-command() {
    if [[ ! -z ${command:-} ]]; then
        debug overriding current command $command with $name
    fi
    name=${command_alias[$1]:-$1}
    command=$name
}

add-command() {
    local short=$1
    local name=$2
    local func=${3:-run-command-$name}
    shift 3
    local help=$@
    parse_arg_func[$name]=parse-command
    if [[ ${enable_short_commands:-true} && ! -z $short ]]; then
        local s
        for s in ${short//,/ }; do
            #parse_arg_func[$s]=parse-command
            arg_alias[$s]=$name
            command_alias[$s]=$name
        done
        help+=" ($short)"
    fi
    command_function[$name]=$func
    command_module[$name]=$module
    command_help[$name]=$help
    command_short[$name]=$short
    command_level[$name]=$help_level
    all_commands+=" $name"
}

show-commands() {
    local cmd
    local len=1
    for cmd in $all_commands; do
        if [[ ${show_help_level:-basic} == *${command_level[$cmd]}* || ${show_help_level:-basic} == all ]]; then
            if (( $len < ${#cmd} )); then len=${#cmd}; fi
        fi
    done #|sort -k2 -k1

    for cmd in $all_commands; do
        if [[ ${show_help_level:-basic} == *${command_level[$cmd]}* || ${show_help_level:-basic} == all ]]; then
            printf "  %-${len}s %s\n" $cmd "${command_help[$cmd]}"
        fi
    done #|sort -k2 -k1
}

run-command() { ${command_function[$command]}; }
