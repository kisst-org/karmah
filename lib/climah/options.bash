
options::declare-vars() {
    declare -gA option_var=()
}

options-show-help() { list-help-items option; }

add-func-option() {
    local short=$1 name=$2 arg=$3 func=$4 summary="$5"
    argparse_parse_func_map[--$name]=$func
    argparse_parse_params[--$name]=$name
    if [[ ! -z $short ]]; then argparse-add-short -$short --$name; fi
    add-help-item option "--$name" "$arg" "$summary"
}

add-parse-option()  { add-func-option "$1" $2 "$3" parse-option-$2 "$4"; }
add-flag-option()   { add-func-option "$1" $2 ""   parse-flag-option "$3"; }
add-value-option()  { add-func-option "$1" $2 "$3" parse-value-option "$4"; }
parse-flag-option()  { set-option-value true; }
parse-value-option() { set-option-value "$2"; argparse_parse_count=2; }

set-option-value() {
    local var_name=${argparse_param_list[0]//-/_}
    eval "$var_name=\"$1\""
}
