# raftah: run actions for all targets

actions::declare-vars() {
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_flow=()
    declare -gA action_module=()
}

actions::init-module() {
    add-help-topic act action "show available actions"
    add-help-topic flw flow   "show available flows"
    append-argparse-func parse-if-action
}

add-action() {
    local short=$1 name=$2 summary="$3"
    log-trace actions "adding action: ${@}"
    if ! $(function-exists action::$name) ; then
        log-error action "adding action $name without function action::$name in module $module"
        exit 1
    fi
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    action_module[$name]=$module
    add-help-item $name action:$name "" "$summary"
}

parse-if-action() {
    local action_name=$1
    if [[ ! -z ${action_module[$action_name]:-} ]]; then
        action_list+=" $action_name"
        argparse_parse_count=1
    fi
}

add-pre-flow-actions() {
    local name actions="$1"; shift
    for name in "${@//,/ }"; do
        local flow=${action_flow[$name]:-}
        if [[ -z $flow ]]; then
            action_flow[$name]=$actions
        else
            action_flow[$name]=$flow,$actions
        fi
        add-help-item "" flow:$name "" "run actions $(get-flow-actions $name)"
    done
}
get-flow-actions() {
    local flow=$1
    local actions=${action_flow[$flow]:-}
    if [[ -z $actions ]]; then
        echo $flow
    else
        # TODO it is currently not possible to have a flow, which does have it self as last action
        echo $actions,$flow
    fi
}


run-action() {
    local action=$1
    if ${action_already_run[$action]:-false}; then
        log-verbose action "skipping $action because it already has run"
        return
    fi
    action_already_run[$action]=true

    local module=${action_module[$action]:-} # This can be used in actions
    log-verbose action "running $action for ${target_name:-$target_path}"
    # log-verbose action "running $action\($argparse_extra_args\) for ${target_name:-$target_path}"
    action::$action
}

run-single-actions() {
    declare -a actions=${@}
    local act; for act in ${actions//,/ }; do
        run-action $act
    done
}

run-flow-actions() {
    local flow=$1
    local actions=$(get-flow-actions $flow)
    log-info action "running flow $flow with actions $actions"
    run-single-actions $actions
}

run-flows() {
    local flows=${1:-}
    if [[ -z $flows ]]; then
        flows=${action_list:-${default_action}}
    fi
    declare -A action_already_run=()
    local post_flow_actions=""
    local flw; for flw in $flows; do
        run-flow-actions $flw
    done
    log-verbose action "running postflow actions: ${post_flow_actions:-}"
    for action in ${post_flow_actions:-}; do run-action $action; done
}


show-actions() { list-help-items action; }

warn-if-action-args() {
    if [[ ! -z ${action_args:-} ]]; then
        log-warn actions "action got action_args \"$action_args\" that is not supported"
    fi
}
error-if-action-args() {
    if [[ ! -z ${action_args:-} ]]; then
        log-error actions "action got action_args \"$action_args\" that is not supported"
        exit 1
    fi
}

log-from-action() { log-at-level $1 "$module.$action" "$2"; }

show-help-about-action() {
    local type=$1 name=$2
    echo $type $name: ${help_item_summary[$type:$name]:-no summary}
    echo
    show-text-for-help-item $type $name
    if $(help-is-verbose); then
        printf "Code:\n"
        type action::$name| tail -n +2
    fi
}
