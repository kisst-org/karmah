# raftah: run actions for all targets

actions-init-climah-vars() {
    declare -g subdir=""
    declare -g flow_name
    declare -g tmp=false
    declare -g action_list=""
    declare -gA action_alias=()
    declare -gA action_flow=()
    declare -gA target_function=()
}

actions-init-climah-module() {
    #add_command "forall" "run actions for all targets"
    command=print-target
    # TODO: commands-add rsa run-single-actions "" "run isolated actions forall targets"
    add-target-action pt print-target "print all target paths"
    help_level=expert
    options-add s subdir dir  "add subdir to list of subdirs (can be comma separated list)"
    options-add-flag T tmp    "render to tmp/manifests (obsolete, tmp is already default), do not commit"
}

parse-option-subdir() { subdir+=" $2"; argparse_parse_count=2; }

add-target-action() { add-action run-for-all-target-paths "${@}"; }
add-action() {
    local cmd_func=$1 short=$2 name=$3 summary="$4"
    debug adding action: "${@}"
    if [[ ! -z $short ]]; then
        action_alias[$short]=$name
    fi
    commands-add "$short" "$name" $cmd_func "$summary"
    help-add-item action "$short" $name "" "$summary"
}

set-pre-actions() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
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

run-action-print-target() { echo $target_path; }

run-for-all-target-paths() {
    target_func=${target_function[$command]:-run-action-$command}
    for target_path in $target_paths; do
        local target_name=$target_path
        $target_func $target_path
    done
}

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
