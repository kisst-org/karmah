
options::declare-vars() {
    declare -gA option_func=()
    declare -gA option_value=()
}

options::init-module() {
    append-argparse-func parse-if-option
}

options-show-help() { list-help-items option; }

get-option-value() {
    local name=$1 default=${2:-}
    local opt_name=${name//_/-}
    echo "${option_value[$opt_name]:-$default}"
}

set-option-value() {
    local name=$1 value="$2"
    log-verbose option "setting option $name to \"$value\""
    option_value[$name]="$value"
}

parse-flag-option() {
    case $1 in
        --$option_name)       set-option-value $option_name true  ;;
        --$option_name=true)  set-option-value $option_name true  ;;
        --$option_name=false) set-option-value $option_name false ;;
        *) log-error option "unsupported syntax for flag option $1"
    esac
}
parse-value-option() {
    local value=${1#*=}
    if [[ $value == $1 ]]; then # --option=...
        value="$2"
        argparse_parse_count=2
    fi
    stderr-trace XXX set-option-value $option_name "$value"
    set-option-value $option_name "$value"
}

parse-if-option() {
    local arg=${1#--}
    if [[ $arg == $1 ]]; then return 0; fi  # not an argument starting with --...

    local option_name=${arg/=*/}
    local func=${option_func[$option_name]:-}
    if [[ -z $func ]]; then return 0; fi   # not a known option
    argparse_parse_count=1 # options that need more argyments can set this
    $func "$@"
}


add-func-option() {
    local short=$1 name=$2 arg=$3 func=$4 summary="$5"
    argparse_parse_func_map[--$name]=$func
    argparse_parse_params[--$name]=$name
    if [[ ! -z $short ]]; then argparse-add-short -$short --$name; fi
    add-help-item --$name option:--$name "$arg" "$summary"
}

add-parse-option()  { add-func-option "$1" $2 "$3" parse-option-$2 "$4"; }
add-flag-option()   {
    local short=$1 name=$2 summary="$3"
    if [[ ! -z $short ]]; then argparse-add-short -$short --$name; fi
    option_func[$name]=parse-flag-option
    add-help-item --$name option:--$name "" "$summary"
}
add-value-option()   {
    local short=$1 name=$2 arg=$3 summary="$4"
    if [[ ! -z $short ]]; then argparse-add-short -$short --$name; fi
    option_func[$name]=parse-value-option
    add-help-item --$name option:--$name "$arg" "$summary"
}

show-help-about-option() {
    local type=$1 name=$2
    echo $type $name: ${help_item_summary[$type:$name]:-no summary}
    echo
    show-text-for-help-item $type $name
}
