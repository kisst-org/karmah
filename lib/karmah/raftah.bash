# raftah: run actions for all targets

init_climah_vars_raftah() {
    declare -g global_vars="karmah_type target"
    declare -g global_arrays=""
    declare -g karmah_paths=""
    declare -g subdir=""
    declare -g flow_name
    declare -g action_list=""
    declare -g all_actions=""
    declare -gA action_module=()
    declare -gA action_level=()
    declare -gA action_help=()
    declare -gA action_flow=()
}

init_climah_module_raftah() {
    #add_command "forall" "run actions for all targets"
    command=render
    help_level=expert
    add-command ""  actions show-actions "show available actions"
    add-option a action act  "add action to list of actions to perform"
    add-option F flow   flw  "use a (custom) flow named <flw>"
    add-list-option s subdir   dir   "add subdir to list of subdirs (can be comma separated list)"
    global_arrays+=" custom_flow"
    global_var+=" run_pre_flow"
}

parse-option-action() { action_list=" $2"; parse_result=2; }

add-action() {
    debug adding action: "${@}"
    local short=$1
    local name=$2
    local flow=$3
    shift 3
    if [[ $short != no-cmd ]]; then
        add-command "$short" $name run-flow "${@}"
    fi
    action_flow[$name]=$flow
    action_help[$name]="$@"
    action_level[$name]=$help_level
    action_module[$name]=$module

    #action_function[$name]=$func
    all_actions+=" $name"
}

run-flow() {
    for path in $karmah_paths; do
        if [[ -f $path ]]; then
            karmah_file=$path
            run_karmah_file
        elif [[ -z ${subdir:-} ]]; then
            karmah_file=($path/*.karmah) # use array for globbing
            run_karmah_file
        else
            for sd in ${subdir//,/ }; do
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

show-actions() {
    local act
    for act in $all_actions; do
        if [[ ${level:-basic} == *${action_level[$act]}* || ${level:-basic} == all ]]; then
            printf "  %-13s %s\n" $act "${action_help[$act]:-no help}"
        fi
    done #|sort -k2 -k1
}
