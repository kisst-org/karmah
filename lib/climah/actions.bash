# raftah: run actions for all targets

actions-init-climah-vars() {
    declare -g subdir=""
    declare -g flow_name
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_alias=()
    declare -gA action_flow=()
}

actions-init-climah-module() {
    help-add-topic act actions "" "show available actions"
    help-add-topic flw flows actions-show-flows "show available flows"
}
actions-show-help() { help-list-items action; }
actions-show-flows() { help-list-items flow; }

add-action() {
    local cmd_func=$1 short=$2 name=$3 summary="$4"
    debug adding action: "${@}"
    if [[ ! -z $short ]]; then
        action_alias[$short]=$name
    fi
    commands-register-func "$short" "$name" $cmd_func
    help-add-item action "$short" $name "" "$summary"
    help-add-item flow   "$short" $name "" "just the single action $name"
    action_flow[$name]=$name  # default flow is just the action
}

set-pre-actions() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
        help-add-item flow "" $name "" "perform the actions ${action_flow[$name]}"
    done

}

run-actions() {
    for action in ${@//,/ }; do
        action=${action_alias[$action]:-$action}
        verbose running $action for ${target_name:-$target_path}
        run-action-$action;
    done
}

run-action-flow() {
    local flow=$1
    local actions=$(add-commas ${action_flow[$flow]:-$flow})
    if ${action_run_single_action:-false}; then
        actions=$flow
    fi
    if [[ -z $argparse_extra_args ]]; then
        info "running actions $actions for ${target_name:-$target_path}"
    else
        info "running actions $actions for ${target_name:-$target_path} with extra arg(s)$argparse_extra_args"
    fi
    for action in ${actions//,/ }; do
        local action_args=""
        if [[ $action == $flow ]]; then
            # Only the action with  should get argparse_extra_args
            action_args="$argparse_extra_args"
        fi
        if [[ -z $action_args ]]; then
            verbose running $action for ${target_name:-$target_path}
        else
            verbose running \"$action $action_args\" for ${target_name:-$target_path}
        fi
        run-action-$action
    done
}

show-actions() { help-list-items action; }

warn-if-action-args() {
    if [[ ! -z ${action_args:-} ]]; then
        warn action got action_args \"$action_args\" that is not supported
    fi
}
error-if-action-args() {
    if [[ ! -z ${action_args:-} ]]; then
        error action got action_args \"$action_args\" that is not supported
        exit 1
    fi
}
