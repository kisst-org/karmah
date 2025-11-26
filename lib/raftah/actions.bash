# run actions for all targets

init_climah_vars_actions() {
    declare -g global_vars="karmah_type target"
    declare -g global_arrays=""
    declare -g karmah_paths=""
    declare -g subdirs=""
    declare -g action_list=""
    declare -gA action_help=()
    declare -gA command_help=()
}

init_climah_module_actions() {
    add_command "forall" "run actions for all targets"
    command=render
    help_level=expert
    add_option a action act  add action to list of actions to perform
}


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

add-flow-command() {
    local short=$1
    local name=$2
    action_list=$3
    shift 3
    local help=$@
    command_function[$name]="run_command_forall"
    command_help[$name]="${help:-${action_help[$name]:-}}"
}



run_command_forall() {
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
        run_actions ${action_list:-render}
    else
        info skipping $karmah_file
    fi
}

run_actions() {
    for action in ${@//,/ }; do
        verbose running $action for ${target}
        run_action_$action;
    done
}
