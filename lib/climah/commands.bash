
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
    add-command ""  commands show-commands "show available commands"
}

add-command() {
    local short=$1
    local name=$2
    local func=${3:-run-command-$name}
    shift 3
    local help=$@
    if [[ ${enable_short_commands:-true} && ! -z $short ]]; then
        local s
        for s in ${short//,/ }; do
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
    for cmd in $all_commands; do
        if [[ ${level:-basic} == *${command_level[$cmd]}* || ${level:-basic} == all ]]; then
            printf "  %-13s %s\n" $cmd "${command_help[$cmd]}"
        fi
    done #|sort -k2 -k1
}
