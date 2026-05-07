help-items::declare-vars() {
    declare -g help_items_to_show=""
    declare -gA help_item_map=()
    declare -gA help_item_summary=()
    declare -gA help_item_module=()
    declare -gA help_item_level=()
    declare -gA help_item_type=()
    declare -gA help_item_params=()
    declare -gA help_all_items=()
}


add-help-item() {
    local short=$1 key=$2 params=$3 summary=$4
    if [[ ! -z $short ]]; then
        help_item_map[$short]+=" $key"
    fi
    local type=${key//:*/}
    help_item_map[$key]=$key
    if [[ -z ${help_item_module[$key]:-} ]]; then
        # do not add a second time
        help_all_items[$type]+=" $key"
    fi
    help_item_module[$key]=$module
    help_item_level[$key]=$help_level
    help_item_params[$key]=$params
    help_item_summary[$key]=$summary
}

parse-if-help-item() {
    local keys=${help_item_map[$1]:-}
    key=${keys# } # items are added to the list with a space
    if [[ ! -z  ${keys} ]]; then
        help_items_to_show+=" $keys";
        argparse_understood_arg=true
    fi
}

help-is-visible() {
    local key=$1
    local lvl=${help_item_level[$key]}
    local mod=${help_item_module[$key]}
    if [[ ${help_show_module:-$mod} != $mod ]]; then
        echo false
    elif [[ ${help_show_level:-basic} == *${lvl}* || ${help_show_level:-basic} == all ]]; then
        echo true
    else
        echo false
    fi
}

has-help-items() {
    local type=$1
    local item len=1 slen=0
    for key in ${help_all_items[$type]:-}; do
        if $(help-is-visible $key); then
            echo true
            return
        fi
    done
    echo false
}

_param-name() {
    local key=$1
    local param=${help_item_params[$key]}
    if [[ ! -z $param ]]; then
        if [[ $param == ... ]]; then
            echo " ..."
        else
            echo " $param"
        fi
    fi
}


list-help-items() {
    local type=$1
    local item len=1 slen=0
    for key in ${help_all_items[$type]:-}; do
        if $(help-is-visible $key); then
            local lname=${key/*:/}
            local name=${key/*:/}
            lname+="$(_param-name $key)"
            if (( $len < ${#lname} )); then len=${#lname}; fi
            local short=${argparse_short_lookup[$name]:-}
            local shortlen=${#short}
            if (( $slen < $shortlen)); then slen=$shortlen; fi
        fi
    done
    for key in ${help_all_items[$type]:-}; do
        local name=${key/*:/}
        local lname=$name
        lname+="$(_param-name $key)"
        if $(help-is-visible $key); then
            printf "  %-${slen}s %-${len}s %s\n" "${argparse_short_lookup[$name]:-}" "$lname" "${help_item_summary[$key]}"
        fi
    done
}
