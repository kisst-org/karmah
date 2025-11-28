
init_climah_vars_options() {
    declare -gA option_short=()
    declare -gA option_arg=()
    declare -gA option_help=()
    declare -gA option_module=()
    declare -gA option_level=()
    declare -g all_options=""
}

init_climah_module_options() {
    add-command ""  options show-options "show available options"
}


add-option() {
    local short=$1
    local name=$2
    local arg=$3
    shift 3
    local help="$@"
    parse_arg_func[--$name]=parse_option_$name
    if [[ ! -z $short ]]; then
        parse_arg_func[-$short]=parse_option_$name
    fi
    option_short[$name]=$short
    option_arg[$name]=$arg
    option_help[$name]="$help"
    option_module[$name]=$module
    option_level[$name]=$help_level
    all_options+=" $name"
}

show-options() {
    local opt
    echo $all_options
    for opt in $all_options; do
        if [[ ${level:-basic} == *${option_level[$opt]}* || ${level:-basic} == all ]]; then
            local head="--$opt ${option_arg[$opt]}"
            if [[ ! -z ${option_short[$opt]} ]]; then
                head="${option_short[$opt]}|$head"
            fi
            printf "  %-20s %s\n" "$head" "${option_help[$opt]}"
        fi
    done #|sort -k2 -k1
}
