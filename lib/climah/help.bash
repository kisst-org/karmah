help::declare-vars() {
    declare -g help_show_level=basic
    declare -gA help_item_map=()
    declare -gA help_item_summary=()
    declare -gA help_item_module=()
    declare -gA help_item_level=()
    declare -gA help_item_type=()
    declare -gA help_item_params=()
    declare -gA help_all_items=()
}

help::init-climah-module() {
    commands-add h  help show-help    "show general help"
    add-parse-option  h  help ""           "show general help information"
    add-parse-option  X  extended-help ""  "show extensive help information"

    add-help-topic al  aliases  argparse-show-aliases "show all defined aliases"
    add-help-topic top topics   show-help-topics "show all help-topics"
    argparse_parse_func[help]=parse-option-help
}

add-help-topic() {
    # TODO: func is not needed anymore
    local short=$1 name=$2 func=${3} summary=${4:-no summary}
    debug adding help-topic: "${@}"
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    add-help-item topic $name "" "$summary"
}

add-help-item() {
    local type=$1 name=$2 params=$3 summary=$4
    local key=$type:$name
    help_item_map[$name]+=" $key"
    help_item_map[$type:$name]=$key
    if [[ -z ${help_item_module[$key]:-} ]]; then
        # do not add a second time
        help_all_items[$type]+=" $name"
    fi
    help_item_module[$key]=$module
    help_item_level[$key]=$help_level
    help_item_params[$key]=$params
    help_item_summary[$key]=$summary
}

help-is-visible() {
    local item=$1
    local lvl=${help_item_level[$item]}
    local mod=${help_item_module[$item]}
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
    for item in ${help_all_items[$type]}; do
        local key=$type:$item
        if $(help-is-visible $key); then
            echo true
            return
        fi
    done
    echo false
}


list-help-items() {
    local type=$1
    local item len=1 slen=0
    for item in ${help_all_items[$type]}; do
        local key=$type:$item
        if $(help-is-visible $key); then
            local lname=$key
            if [[ ! -z ${help_item_params[$key]} ]]; then
                lname+=" <${help_item_params[$key]}>"
            fi
            if (( $len < ${#lname} )); then len=${#lname}; fi
            local short=${argparse_short_lookup[$item]:-}
            local shortlen=${#short}
            if (( $slen < $shortlen)); then slen=$shortlen; fi
        fi
    done
    for item in ${help_all_items[$type]}; do
        local lname=$item
        local key=$type:$item
        if [[ ! -z ${help_item_params[$key]} ]]; then
            lname+=" <${help_item_params[$key]}>"
        fi
        if $(help-is-visible $key); then
            printf "  %-${slen}s %-${len}s %s\n" "${argparse_short_lookup[$item]:-}" "$lname" "${help_item_summary[$key]}"
        fi
    done
}

parse-option-help() { command_to_run=help;  }
parse-option-extended-help() { help_show_level=all;  }

show-help() {
    local found=false
    local unknown_topics=""
    #for arg in $argparse_parsed_args $argparse_extra_args $argparse_unknown_args ; do
    for arg in $argparse_original_args ; do
        arg=${argparse_short_map[$arg]:-$arg}
        local key; for key in ${help_item_map[$arg]:-}; do
            if [[ $key == command:help ]]; then continue; fi
            if [[ $key == option:--help ]]; then continue; fi
            find-help-item
        done
    done
    if ! $found; then
        if [[ ${help_show_level:-} == all ]]; then
            ${climah_help_full_function:-${climah_prog}-show-full-help}
        else
            show-short-help
        fi
    fi
    if [[ ! -z $unknown_topics ]]; then
        if $found; then
            echo ----------------------------
        fi
        echo unknown arguments $unknown_topics
    fi

}

find-help-item() {
    if [[ ! -z  $key ]] ; then
        local type=${key%:*}
        local name=${key#*:}
        local func=show-help-about-$type
        if ! $(function-exists $func); then
            func=show-type-help
        fi
        if $found; then
            echo ----------------------------
        fi
        $func $type $name
        found=true
    else
        if [[ ! -e $arg ]]; then # skip files and directories
            unknown_topics+=" $arg"
        fi
    fi
}

show-type-help() {
    local type=$1 name=$2
    local short=${argparse_short_lookup[$name]:-}
    if [[ -z $short ]]; then
        echo "$type $short $name: ${help_item_summary[$type:$name]}"
    else
        echo "$type $name (or $short): ${help_item_summary[$type:$name]}"
    fi
    # TODO: uit help text
}

show-short-help() {
  echo Options:
  options-show-help
  echo
  echo Commands/actions:
  commands-show-help
  list-help-items command
  list-help-items action
  echo
  echo see additional help topics with
  echo "   ${climah_prog_name} help topics"
}

show-help-topics() {
cat <<EOF
${climah_prog_name} help [<topic>]

topic can be any of:
EOF
    list-help-items topic;
}
