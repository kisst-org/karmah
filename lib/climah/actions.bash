# raftah: run actions for all targets

actions::declare-vars() {
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_flow=()
}

actions::init-climah-module() {
    help-add-topic act actions "" "show available actions"
    help-add-topic flw flows actions-show-flows "show available flows"
    help_level=expert
    add-flag-option "" run-single-action  "run just the action, not the (pre)flow"
}
actions-show-help() { help-list-items action; }
actions-show-flows() { help-list-items flow; }

add-action() {
    local short=$1 name=$2 summary="$3"
    debug adding action: "${@}"
    argparse_parse_func[$name]=parse-action
    argparse_parse_params[$name]=$name
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    : ${action_flow[$name]:=$name}  # default flow is just the action
    help-add-item action $name "" "$summary"
}

parse-action() { action_list+=" ${argparse_param_list[0]}"; }

set-action-pre-flow() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
        help-add-item flow $name "" "run actions ${action_flow[$name]:-$name}"
    done
}

run-verbose-action() {
    local action=$1
    if [[ -z  $argparse_extra_args ]]; then
        verbose running $action for ${target_name:-$target_path}
    else
        verbose running $action\($argparse_extra_args\) for ${target_name:-$target_path}
    fi
    run-action-$action
}

run-single-actions() {
    declare -a actions=${@:-${action_list:-${default_action}}}
    local action
    for action in ${actions//,/ }; do
        run-verbose-action $action
    done
}

run-flow-actions() {
    declare -a flows=${@:-${action_list:-${default_action}}}
    declare -A action_already_run=()
    local action flow
    info running flow-actions $flows
    for flow in ${flows//,/ }; do
        flow=${action_flow[$flow]:-$flow}
        for action in ${flow//,/ }; do
            if ${action_already_run[$action]:-false}; then
                info "skipping $action because it already has run"
            else
                action_already_run[$action]=true
                run-verbose-action $action
            fi
        done
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
