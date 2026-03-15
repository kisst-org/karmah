
options::init-climah-vars() {
    declare -gA option_var=()
}

options::init-climah-module() {
    help-add-topic opt options "" "show available commands"
}

options-show-help() { help-list-items option; }

options-add-generic() {
    local short=$1 name=$2 arg=$3 func=$4 summary="$5"
    argparse_parse_func[--$name]=$func
    argparse_parse_params[--$name]=$name
    if [[ ! -z $short ]]; then argparse-add-short -$short --$name; fi
    help-add-item option "--$name" "$arg" "$summary"
}

options-add()           { options-add-generic "$1" $2 "$3" parse-option-$2 "$4"; }
options-add-flag()      { options-add-generic "$1" $2 ""   options-parse-flag "$3"; }
options-add-value-opt() { options-add-generic "$1" $2 "$3" options-parse-value-opt "$4"; }
options-parse-flag()      { options-set-value true; }
options-parse-value-opt() { options-set-value "$2"; argparse_parse_count=2; }

options-set-value() {
    local var_name=${argparse_param_list[0]//-/_}
    eval $var_name="$1"
}
