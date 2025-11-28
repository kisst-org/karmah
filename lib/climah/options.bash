
init_climah_vars_options() {
    declare -gA option_short=()
    declare -gA option_arg=()
    declare -gA option_help=()
    declare -gA option_module=()
    declare -gA option_level=()
    declare -gA option_var=()
    declare -g all_options=""
}

init_climah_module_options() {
    add-command ""  options show-options "show available options"
}


add-generic-option() {
    local short=$1
    local name=$2
    local arg=$3
    local func=$4
    shift 4
    local help="$@"
    parse_arg_func[--$name]=$func
    option_var[--$name]=${name//-/_}
    if [[ ! -z $short ]]; then
        parse_arg_func[-$short]=$func
        option_var[-$short]=${name//-/_}
    fi
    option_short[$name]=$short
    option_arg[$name]=$arg
    option_help[$name]="$help"
    option_module[$name]=$module
    option_level[$name]=$help_level
    all_options+=" $name"
}

add-option() {
    local short=$1
    local name=$2
    local arg=$3
    shift 3
    add-generic-option "$short" $name "$arg" parse-option-$name "$@"
}

add-flag-option() {
    local short=$1
    local name=$2
    shift 2
    add-generic-option "$short" $name "" parse-flag-option "$@"
}

add-value-option() {
    local short=$1
    local name=$2
    local arg=$3
    shift 3
    add-generic-option "$short" $name "$arg" parse-value-option "$@"
}


parse-flag-option() {
    eval ${option_var[$1]}=true
}
parse-value-option() {
    eval ${option_var[$1]}=$2
    parse_result=2
}


show-options() {
    local opt
    for opt in $all_options; do
        if [[ ${level:-basic} == *${option_level[$opt]}* || ${level:-basic} == all ]]; then
            local head="--$opt ${option_arg[$opt]}"
            if [[ ! -z ${option_short[$opt]} ]]; then
                head="${option_short[$opt]}|$head"
            fi
            printf "  %-25s %s\n" "$head" "${option_help[$opt]}"
        fi
    done #|sort -k2 -k1
}
