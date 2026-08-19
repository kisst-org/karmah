
actions::declare-vars() {
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_module=()
    declare -gA action_uses_unknown_args=()
    declare -gA action_karmah_vars=()
}

actions::init-module() {
    add-help-topic act action "show available actions"
    append-argparse-func parse-if-action
    help_level=expert
    local action_params=...
    declare-action dpav debug-print-action-var "print a variable declaration for debugging purposes"
    add-flag-option P skip-pre-actions  "do not execute any pre-actions"
}

action::debug-print-action-var() { command::debug-print-var "$@"; }

add-action-karmah-vars() { local act=$1; shift; add-karmah-vars-for-actions "$*" $act; }
set-action-karmah-vars() { local act=$1; shift; set-karmah-vars-for-actions "$*" $act; }
add-karmah-vars-for-actions() {
    local vars=$1 actions=$2
    if [[ $vars == "all-vars-known-in-module" ]]; then
        vars=""
        local v; for v in ${!karmah_var_module[@]}; do
            if [[ ${karmah_var_module[$v]} == $module ]]; then
                vars+=" $v"
            fi
        done
    fi
    local a; for a in ${actions//,/ }; do
        action_karmah_vars[$a]+=" ${vars//,/ }"
    done
}
set-karmah-vars-for-actions() {
    local vars=$1 actions=$2
    local a; for a in ${actions//,/ }; do
        action_karmah_vars[$a]="${vars//, /}"
    done
}

declare-action() {
    local short=$1 name=$2 summary="$3" vars=${4:-${use_karmah_vars:-all-vars-known-in-module}}
    log-trace actions "adding action: ${@}"
    if ! $(function-exists action::$name) ; then
        log-error action "adding action $name without function action::$name in module $module"
        exit 1
    fi
    add-karmah-vars-for-actions "${vars}" $name
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    action_module[$name]=$module
    if [[ ! -z ${action_params:-} ]]; then
        action_uses_unknown_args[$name]=true
    fi
    add-help-item "$short" $name action:$name "${action_params:-}" "$summary"
}

strip-action-prefix() {
    local action=$1
    case $action in
        always:*) echo ${action#always:} ;;
        single:*) echo ${action#single:} ;;
        *)        echo $action;;
    esac
}

parse-if-action() {
    local action=$(strip-action-prefix $1)
    if [[ ! -z ${action_module[$action]:-} ]]; then
        action_list+=" $1" # keep the prefix
        argparse_parse_count=1
        if ${action_uses_unknown_args[$action]:-false}; then
            ignore_unknown_args=true
        fi
    fi
}

run-action() {
    local action=$(strip-action-prefix $1)
    if ${action_already_run[$action]:-false}; then
        if [[ $1 == always:$action ]]; then
            log-verbose action "running $action again, because of always:prefix"
        else
            log-verbose action "skipping $action because it already has run"
            return
        fi
    fi
    action_already_run[$action]=true

    local module=${action_module[$action]:-} # This can be used in actions
    local params=""
    if ${action_uses_unknown_args[$action]:-false}; then
        params="$argparse_unknown_args $argparse_remaining_args"
        log-verbose action "running $action for ${target_name:-$target_path} with params $params"
    else
        log-verbose action "running $action for ${target_name:-$target_path}"
    fi
    local v; for v in ${action_karmah_vars[$action]}; do
        use-karmah-var $v
    done
    action::$action $params
}

run-actions() {
    declare -a actions=${@}
    local abort_actions=false
    local act; for act in ${actions//,/ }; do
        run-action $act
        if $abort_actions; then
            return # TODO: should this be non 0 return code?
        fi
    done
}
run-pre-actions() {
    if $(get-option-value skip-pre-actions false); then
        log-verbose actions "skipping pre-actions $*"
    else
      run-actions "$@"
    fi
}

show-actions() { list-help-items action; }

log-from-action() { log-at-level $1 "$module.$action" "$2"; }
action-log() { log-at-level $1 "$module.$action" "$2"; }

show-help-about-action() {
    local key=$1
    local item=${key/*::/}
    local type=${item/:*/}  name=${item/*:/}
    echo action $name: ${help_item_summary[$key]:-no summary}
    echo
    show-text-for-help-item $key
    # type action::$name| grep run-actions

    printf "karmah-vars for $name:\n"
    local keys=""
    local v; for v in ${action_karmah_vars[$name]}; do
        keys+=" ${karmah_var_module[$v]}::karmah-var:--${v//_/-}"
    done
    show-help-items $keys

    if $(help-is-verbose); then
        printf "Code:\n"
        type action::$name| tail -n +2
    fi
}
