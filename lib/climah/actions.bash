# raftah: run actions for all targets

actions::init-climah-vars() {
    declare -g run_single_action=false

    declare -g action_to_run
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_flow=()
    declare -gA action_target_func=()
}

actions::init-climah-module() {
    help-add-topic act actions "" "show available actions"
    help-add-topic flw flows actions-show-flows "show available flows"
    help_level=expert
    options-add-flag "" run-single-action  "run just the action, not the (pre)flow"

}
actions-show-help() { help-list-items action; }
actions-show-flows() { help-list-items flow; }

add-action() {
    local cmd_func=$1 short=$2 name=$3 summary="$4"
    debug adding action: "${@}"
    argparse_parse_func[$name]=parse-action
    argparse_parse_params[$name]=$name
    action_target_func[$name]=$cmd_func
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    : ${action_flow[$name]:=$name}  # default flow is just the action
    help-add-item action $name "" "$summary"
}

parse-action() {
    command_to_run=run-flow
    action_to_run=${argparse_param_list[0]}
    target_func=run-karmah-path #${action_target_func[$action_to_run]}
}

set-action-pre-flow() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
        help-add-item flow $name "" "run actions ${action_flow[$name]:-$name}"
    done
}

run-actions() {
    local action
    for action in ${@//,/ }; do
        local action_args=""
        if [[ $action == $action_to_run ]]; then
            # Only the action with  should get argparse_extra_args
            action_args="$argparse_extra_args"
        fi
        verbose running $action\($action_args\) for ${target_name:-$target_path}
        run-action-$action
    done
}

run-action-flow() {
    local flow=${action_flow[$action_to_run]}
    if ${run_single_action}; then flow=$action_to_run; fi
    local actions=$(add-commas $flow)
    if [[ -z $argparse_extra_args ]]; then
        info "running actions $actions for ${target_name:-$target_path}"
    else
        info "running actions $actions for ${target_name:-$target_path} with extra arg(s) ${argparse_extra_args% }"
    fi
    run-actions ${actions}
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
