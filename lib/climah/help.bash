help-init-climah-vars() {
    declare -g help_show_level=basic
    declare -gA help_topic_function=()
    declare -gA help_topic_params=()

    declare -gA help_item_summary=()
    declare -gA help_item_module=()
    declare -gA help_item_level=()
    declare -gA help_item_type=()
    declare -gA help_item_params=()
    declare -gA help_all_items=()
}

help-init-climah-module() {
    commands-add h  help show-help    "show general help"
    options-add  h  help ""           "show general help information"
    options-add  X  extended-help ""  "show extensive help information"

    help-add-topic al  aliases  argparse-show-aliases "show all defined aliases"
    help-add-topic top topics   show-help-topics "show all help-topics"
    argparse_parse_func[help]=parse-option-help
}

help-add-topic() {
    local short=$1 name=$2 func=${3} summary=${4:-no summary}
    help_topic_function[$name]=${func:-$name-show-help}
    help_topic_params[$name]=$name;
    if [[ ! -z $short ]]; then
        help_topic_function[$short]=${func:-$name-show-help}
        help_topic_params[$short]=$name;
        argparse-add-short $short $name
    fi
    help-add-item topic $name "" "$summary"
}

help-add-item() {
    local type=$1 name=$2 params=$3 summary=$4
    local key=$type:$name
    help_item_module[$key]=$module
    help_item_level[$key]=$help_level
    help_item_params[$key]=$params
    help_item_summary[$key]=$summary
    help_all_items[$type]+=" $name"
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

help-list-items() {
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


add-help() {
  local section=$1
  local name=$2
  local option=$3
  shift 3
  help_text[$help_level,$section,$module,$name]+="${@}"
}

help-show-module() {
    echo help_show_module=$1
    help_show_level=all
    echo ${module_summary[$help_show_module]}
    commands-show-help
    echo
    echo "Options:"
    options-show-help
}

show-help() {
    local found=false
    for arg in $argparse_extra_args; do
        if [[ ! -z ${help_topic_function[$arg]:-} ]] ; then
            ${help_topic_function[$arg]} "${help_topic_params[$arg]}"
            found=true
        else
          warn unknown help topic $arg
          show-help-topics
          exit 1
        fi
    done
    if ! $found; then
        if [[ ${help_show_level:-} == all ]]; then
            ${climah_help_full_function:-${climah_prog}-show-full-help}
        else
            help-show-summary
        fi
    fi
}

help-show-summary() {
  echo Options:
  options-show-help
  echo
  echo Commands/actions:
  commands-show-help
  help-list-items command
  help-list-items action
  echo
  echo see additional help topics with
  echo "   ${climah_prog_name} help topics"
}

show-help-topics() {
cat <<EOF
${climah_prog_name} help [<topic>]

topic can be any of:
EOF
    help-list-items topic;
}
