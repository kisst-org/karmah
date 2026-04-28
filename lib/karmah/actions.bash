# raftah: run actions for all targets

actions::declare-vars() {
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_flow=()
    declare -gA action_module=()
    declare -gA action_pre_hook=()
}

actions::init-module() {
    add-help-topic act action "" "show available actions"
    add-help-topic flw flow actions-show-flows "show available flows"
    help_level=expert
    add-flag-option "" run-single-action  "run just the action, not the (pre)flow"
}
actions-show-help() { list-help-items action; }
actions-show-flows() { list-help-items flow; }

add-action() {
    local short=$1 name=$2 summary="$3"
    log-debug actions "adding action: ${@}"
    argparse_parse_func_map[$name]=parse-action
    argparse_parse_params[$name]=$name
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    : ${action_flow[$name]:=$name}  # default flow is just the action
    action_module[$name]=$module
    add-help-item $name action:$name "" "$summary"
}

parse-action() {
    action_list+=" ${argparse_param_list[0]}";
    add-help-item-to-show "${argparse_param_list[0]}"
}

set-action-pre-hook() { action_pre_hook[$1]=$2; }
set-action-pre-flow() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
        add-help-item "" flow:$name "" "run actions ${action_flow[$name]:-$name}"
    done
}

run-verbose-action() {
    local action=$1
    local pre_hook=${action_pre_hook[$action]:-}
    local module=${action_module[$action]}
    if [[ ! -z ${pre_hook}  ]]; then
        log-info action "running action pre-hook ${pre_hook}"
        ${pre_hook}
    fi
    if [[ -z  $argparse_extra_args ]]; then
        log-verbose action "running $action for ${target_name:-$target_path}"
    else
        log-verbose action "running $action\($argparse_extra_args\) for ${target_name:-$target_path}"
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
    log-info action "running flow-actions $flows"
    for flow in ${flows//,/ }; do
        flow=${action_flow[$flow]:-$flow}
        for action in ${flow//,/ }; do
            if ${action_already_run[$action]:-false}; then
                log-info action "skipping $action because it already has run"
            else
                action_already_run[$action]=true
                run-verbose-action $action
            fi
        done
    done
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
run-cmd-from-action() {
    local level=$1 cmd=$2
    shift 2
    run-and-log-cmd $level cmd.$module.$cmd $cmd "$@"
}

show-help-about-action() {
    local type=$1 name=$2
    echo $type $name: ${help_item_summary[$type:$name]:-no summary}
    echo
    local module=${help_item_module[$type:$name]}
    show-module-md-text $module | sed -n "/^## action $name/,/^## /p" | grep -v '^##'
    printf "\nCode:\n"
    type run-action-$name| tail -n +2
}
