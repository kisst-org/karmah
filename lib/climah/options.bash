
options-init-climah-vars() {
    declare -gA option_var=()
}

options-init-climah-module() {
    help-add-topic opt options  show-options "show all options"
}

add-generic-option() {
    local short=$1 name=$2 arg=$3 func=$4 summary="$5"
    argparse_arg_func[--$name]=$func
    argparse_arg_params[--$name]=${name//-/_}
    if [[ ! -z $short ]]; then
        argparse_arg_func[-$short]=$func
        argparse_arg_params[-$short]=${name//-/_}
    fi
    help-add-item option "$short" "--$name" "$arg" "$summary"
}

add-option() {
    local short=$1 name=$2 arg=$3 summary=$4
    add-generic-option "$short" $name "$arg" parse-option-$name "$summary"
}

# helper function for add-...-options below with name and short set
_option-set-varname() {
    local varname=${1:-${name//-/_}}
    argparse_arg_params[--$name]=$varname
    if [[ ! -z $short ]]; then
        argparse_arg_params[-$short]=${name//-/_}
    fi
}

add-flag-option() {
    local short=$1 name=$2 summary=$3
    #_option-set-varname
    add-generic-option "$short" $name "" parse-flag-option "$summary"
}

add-value-option() {
    local short=$1 name=$2 arg=$3 summary=$4
    _option-set-varname
    add-generic-option "$short" $name "$arg" parse-value-option "$summary"
}

add-list-option() {
    local short=$1 name=$2 arg=$3 summary=$4
    _option-set-varname
    add-generic-option "$short" $name "$arg" parse-list-option "$summary"
}


parse-flag-option() {
    local var_name=${argparse_params}
    eval $var_name=true
}
parse-value-option() {
    local var_name=${argparse_params}
    eval $var_name=\"$2\"
    argparse_parse_count=2
}
parse-list-option() {
    local var_name=${argparse_params}
    local var=${option_var[$var_name]}
    eval $var_name+=\" $2\"
    argparse_parse_count=2
}

show-options() {
    info All available options:
    #local help_show_level=all
    help-list-items option;
}
