
options::declare-vars() {
    declare -gA option_type=()
    declare -gA option_value=()
}

options::init-module() {
    append-argparse-func parse-if-option
}


options-show-help() { list-help-items option; }

parse-if-option() {
    local arg=${1}
    arg=${arg#--}
    if [[ $arg == $1 ]]; then
        return
    fi
    local name=${arg/=*/}
    local value="${arg/*=/}"
    argparse_parse_count=1
    case ${option_type[$name]:-none} in
        value)
            if [[ $value == $arg ]]; then # not format --opt=val
                option_value[$name]="${2}"
                argparse_parse_count=2
            else
                option_value[$name]="$value"
                help_items_to_show+=" --$name"
            fi
            ;;
        flag)
            if [[ $value == $arg ]]; then # not format --opt=val
                option_value[$name]=true
            else
                option_value[$name]="$value"
                help_items_to_show+=" --$name"
            fi
            ;;
        none)    argparse_parse_count=0;;
    esac
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
    option_type[$name]=flag
    add-help-item --$name option:--$name "" "$summary"
}
add-value-option()   {
    local short=$1 name=$2 arg=$3 summary="$4"
    if [[ ! -z $short ]]; then argparse-add-short -$short --$name; fi
    option_type[$name]=value
    add-help-item --$name option:--$name "$arg" "$summary"
}

show-help-about-option() {
    local type=$1 name=$2
    echo $type $name: ${help_item_summary[$type:$name]:-no summary}
    echo
    show-text-for-help-item $type $name
}
