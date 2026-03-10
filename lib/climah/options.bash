
init_climah_vars_options() {
    declare -gA option_arg=()
    declare -gA option_var=()
}

init_climah_module_options() {
    help-add-topic opt options  show-options "show all options"
}


add-generic-option() {
    local short=$1 name=$2 arg=$3 func=$4 summary="$5"
    parse_arg_func[--$name]=$func
    option_var[--$name]=${name//-/_}
    if [[ ! -z $short ]]; then
        short=-$short
        parse_arg_func[$short]=$func
        option_var[$short]=${name//-/_}
    fi
    option_arg[$name]=$arg
    help-add-item option "$short" "--$name" "$arg" "$summary"
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

add-list-option() {
    local short=$1
    local name=$2
    local arg=$3
    shift 3
    add-generic-option "$short" $name "$arg" parse-list-option "$@"
}


parse-flag-option() {
    eval ${option_var[$1]}=true
}
parse-value-option() {
    eval ${option_var[$1]}=\"$2\"
    parse_result=2
}
parse-list-option() {
    local var=${option_var[$1]}
    eval ${var}+=\" $2\"
    parse_result=2
}

show-options() { help-list-items option; }
