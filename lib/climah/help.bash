help::declare-vars() {
    declare -g help_show_level=basic
}

help::init-module() {
    add-command h  help show-help    "show general help"
    add-func-option  h  help ""           "show general help information"
}

help-is-verbose() { logger-shows-level help verbose; }

set-help-level() {
    local level=$1; shift
    local item; for item in "$@"; do
        help_item_level[$item]=level
    done
}



option::help() { command_to_run=help;  }

show-help() {
    local found=false
    local unknown_topics=""
    log-verbose help "showing help about ${help_items_to_show# }"
    for arg in $help_items_to_show ; do
        for key in ${help_item_map[$arg]:-$arg}; do
            if [[ $key == help::* ]]; then continue; fi
            find-help-item $key
        done
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
    local key=$1
    if [[ ! -z  $key ]] ; then
        key=${help_item_map[$key]:-$key}
        #local module=${key/::*/}
        local item=${key/*::/}
        local type=${item/:*/}
        #local name=${item/*:/}
        local func=show-help-about-$type
        if ! $(function-exists $func); then
            func=show-type-help
        fi
        if $found; then
            echo ----------------------------
        fi
        $func $key
        found=true
    else
        if [[ ! -e $arg ]]; then # skip files and directories
            unknown_topics+=" $arg"
        fi
    fi
}

show-type-help() {
    #local type=$1 name=$2
    local key=$1
    local key=${help_item_map[$name]:-}
    local short=${help_item_short[$key]:-}
    if [[ -z $short ]]; then
        echo "$type $short $name: ${help_item_summary[$key]}"
    else
        echo "$type $name (or $short): ${help_item_summary[$key]}"
    fi
    # TODO: uit help text
}

show-basic-help() {
  echo Options:
  options-show-help
  echo
  echo see additional help topics with
  echo "   ${climah_prog_name} help topic"
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
  echo "   ${climah_prog_name} help topic"
}
