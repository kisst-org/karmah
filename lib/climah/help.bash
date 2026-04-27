help::declare-vars() {
    declare -g help_show_level=basic
    declare -g help_items_to_show=""
    declare -gA help_item_map=()
    declare -gA help_item_summary=()
    declare -gA help_item_module=()
    declare -gA help_item_level=()
    declare -gA help_item_type=()
    declare -gA help_item_params=()
    declare -gA help_all_items=()
}

help::init-module() {
    commands-add h  help show-help    "show general help"
    add-parse-option  h  help ""           "show general help information"
    add-parse-option  X  extended-help ""  "show extensive help information"

    add-help-topic al  aliases  argparse-show-aliases "show all defined aliases"
    add-help-topic top topics   show-help-topics "show all help-topics"
    argparse_parse_func_map[help]=parse-option-help
    append-argparse-func parse-help-topic
    append-argparse-func parse-help-item
}
parse-help-topic() {
    local name=$1
    if [[ -z ${help_item_module[$name]:-} ]]; then return 0; fi
    command_to_run=help
    help_items_to_show+=" $name"
    argparse_parse_count=1;
}


set-help-level() {
    local level=$1; shift
    local item; for item in "$@"; do
        help_item_level[$item]=level
    done
}

add-help-topic() {
    # TODO: func is not needed anymore
    local short=$1 name=$2 func=${3} summary=${4:-no summary}
    debug adding help-topic: "${@}"
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    add-help-item $name topic:$name "" "$summary"
}

add-help-item() {
    local short=$1 key=$2 params=$3 summary=$4
    if [[ ! -z $short ]]; then
        help_item_map[$short]=$key
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
    argparse_parse_func_map[$key]=parse-help-item
}
parse-help-item() {
    help_items_to_show+=" $1"
    command_to_run=help;
    argparse_parse_count=1;
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
    for key in ${help_all_items[$type]}; do
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
    for key in ${help_all_items[$type]}; do
        if $(help-is-visible $key); then
            local lname=${key/*:/}
            local name=${key/*:/}
            if [[ ! -z ${help_item_params[$key]} ]]; then
                lname+=" <${help_item_params[$key]}>"
            fi
            if (( $len < ${#lname} )); then len=${#lname}; fi
            local short=${argparse_short_lookup[$name]:-}
            local shortlen=${#short}
            if (( $slen < $shortlen)); then slen=$shortlen; fi
        fi
    done
    for key in ${help_all_items[$type]}; do
        local name=${key/*:/}
        local lname=$name
        if [[ ! -z ${help_item_params[$key]} ]]; then
            lname+=" <${help_item_params[$key]}>"
        fi
        if $(help-is-visible $key); then
            printf "  %-${slen}s %-${len}s %s\n" "${argparse_short_lookup[$name]:-}" "$lname" "${help_item_summary[$key]}"
        fi
    done
}

parse-option-help() { command_to_run=help;  }
parse-option-extended-help() { help_show_level=all;  }

add-arg-to-help() { help_items_to_show+=" $1"; }
show-help() {
    local found=false
    local unknown_topics=""
    #for arg in $argparse_parsed_args $argparse_extra_args $argparse_unknown_args ; do
    log-info help "showing help about ${help_items_to_show# }"
    for arg in $help_items_to_show ; do
        local key=${argparse_short_map[$arg]:-$arg}
        key=${help_item_map[$key]:-$key}
        if [[ $key == command:help ]]; then continue; fi
        if [[ $key == option:--help ]]; then continue; fi
        if [[ $key == option:--verbose ]]; then continue; fi
        find-help-item
    done
    if ! $found; then
        if [[ ${help_show_level:-} == all ]]; then
            ${help_full_function:-${climah_prog}::show-full-help}
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
        key=${help_item_map[$key]:-$key}
        local type=${key/:*/}
        local name=${key/*:/}
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
    if [[ ! -z $short ]]; then
        echo "$type $short $name: ${help_item_summary[$type:$name]}"
    else
        echo "$type $name (or $short): ${help_item_summary[$type:$name]}"
    fi
    # TODO: uit help text
}

show-basic-help() {
  echo Options:
  options-show-help
  echo
  echo see additional help topics with
  echo "   ${climah_prog_name} help topics"
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
    list-help-items topic
}
