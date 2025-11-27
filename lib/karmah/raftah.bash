# raftah: run actions for all targets

init_climah_vars_raftah() {
    declare -g global_vars="karmah_type target"
    declare -g global_arrays=""
    declare -g karmah_paths=""
    declare -g subdirs=""
    declare -g flow_name
    declare -g action_list=""
    declare -g all_actions=""
    #declare -gA action_help=()
    declare -gA action_flow=()
}

init_climah_module_raftah() {
    #add_command "forall" "run actions for all targets"
    command=render
    help_level=expert
    add_option a action act  "add action to list of actions to perform"
    add_option F flow   flw  "use a (custom) flow named <flw>"
    global_arrays+=" custom_flow"
    global_var+=" run_pre_flow"
}

parse_option_action() { action_list=" $2"; parse_result=2; }
parse_append_action() { action_list+=$1;  }
parse_append_action_with_args() { action_list+=$1; collect_unknown_args=true; }
add_action() {
    local name=$1
    shift 1
    if [[ ${1:-} == --collect ]]; then
        shift
        parse_arg_func[$name]=parse_append_action_with_args
    else
        parse_arg_func[$name]=parse_append_action
    fi
    local help="$@"
    add_help_text action "$(printf "\n  %-13s %s" "$name" "$help")"
    action_help[$name]=$help
}


add-action() {
    debug adding action: "${@}"
    local short=$1
    local name=$2
    local flow=$3
    shift 2
    if [[ $short != no-cmd ]]; then
        add-command "$short" $name run-flow "${@}"
    fi
    action_flow[$name]=$flow
    #action_function[$name]=$func
    all_actions+=" $name"
}

run-flow() {
    for path in $karmah_paths; do
        if [[ -f $path ]]; then
            karmah_file=$path
            run_karmah_file
        elif [[ -z ${subdirs:-} ]]; then
            karmah_file=($path/*.karmah) # use array for globbing
            run_karmah_file
        else
            for sd in ${subdirs//,/ }; do
                karmah_file=($path/$sd/*.karmah)  # use array for globbing
                run_karmah_file
            done
        fi
    done
}

init_karmah_type_basic() {
    verbose using empty karmah_type initializer
}

run_karmah_file() {
    local karmah_type

    if [[ -f "${karmah_file}" ]]; then
        # cleanup of any vars that might have been set with previous file
        debug clearing $global_vars $global_arrays
        unset $global_vars $global_arrays
        declare -g $global_vars
        declare -gA $global_arrays
        verbose loading ${karmah_file}
        local karmah_dir=$(dirname $karmah_file)
        local common_dir=$(dirname $karmah_dir)/common
        local used_files=${karmah_dir}
        local common_karmnah_file=($common_dir/common*.karmah)
        if [[ -f $common_karmnah_file ]]; then
            source $common_karmnah_file
        fi
        source ${karmah_file}
        init_karmah_type_${karmah_type:-basic}
        output_dir="${to_dir:-tmp/manifests}/${target}"
        local actions=${action_flow[$command]:-$action_list}
        actions=${custom_flow[${command:-none}]:-$actions}
        run_actions $actions $command
    else
        info skipping $karmah_file
    fi
}

run_actions() {
    for action in ${@//,/ }; do
        verbose running $action for ${target}
        run-action-$action;
    done
}
