# raftah: run actions for all targets

init_climah_vars_raftah() {
    declare -g local_vars="karmah_type target"
    declare -g local_arrays=""
    declare -g karmah_paths=""
    declare -g subdir=""
    declare -g flow_name
    declare -g tmp=false
    declare -g action_list=""
    declare -g all_actions=""
    declare -gA action_module=()
    declare -gA action_level=()
    declare -gA action_help=()
    declare -gA action_flow=()
    declare -gA action_alias=()
}

init_climah_module_raftah() {
    #add_command "forall" "run actions for all targets"
    command=run-actions
    add-command run run-actions ""   "run actions forall targets"
    add-command ""  actions show-actions "show available actions"
    help_level=expert
    add-option a add-actions act  "add action to list of actions to perform"
    add-option A set-actions act  "set the action to list of actions to perform"
    add-option F flow   flw  "use a (custom) flow named <flw>"
    add-flag-option T tmp    "render to tmp/manifests, do not commit"
    add-list-option s subdir   dir   "add subdir to list of subdirs (can be comma separated list)"
    add-value-option K force-karmah-type typ "force to use another karmah_type"
    local_arrays+=" custom_flow"
    local_var+=" run_pre_flow"
}

parse-option-add-actions() { action_list+=" $2"; parse_result=2; }
parse-option-set-actions() { action_list=" $2"; parse_result=2; }

add-action() {
    debug adding action: "${@}"
    local short=$1
    local name=$2
    parse_arg_func[$name]=parse-action
    shift 2
    local help="$*"
    if [[ ${enable_short_commands:-true} && ! -z $short ]]; then
        local s
        for s in ${short//,/ }; do
            arg_alias[$s]=$name
            action_alias[$s]=$name
        done
        help+=" ($short)"
    fi
    action_help[$name]="$help"
    action_level[$name]=$help_level
    action_module[$name]=$module
    #action_function[$name]=$func
    all_actions+=" $name"
}

parse-action() {
    local name=${action_alias[$1]:-$1}
    action_list+=" ${action_flow[$name]:-$name}"
    #actions=${custom_flow[${command:-none}]:-$actions}
    command=run-actions
}

set-pre-actions() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
    done

}

run-command-run-actions() {
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
        debug clearing $local_vars $local_arrays
        unset $local_vars $local_arrays
        declare $local_vars
        declare -A $local_arrays
        verbose loading ${karmah_file}
        local karmah_dir=$(dirname $karmah_file)
        local common_dir=$(dirname $karmah_dir)/common
        local used_files=${karmah_dir}
        local common_karmnah_file=($common_dir/common*.karmah)
        if [[ -f $common_karmnah_file ]]; then
            debug loading $common_karmnah_file
            source $common_karmnah_file
        fi
        source ${karmah_file}
        karmah_type=${force_karmah_type:-${karmah_type:-basic}}
        init_karmah_type_${karmah_type:-basic}
        output_dir="${to_dir:-deployed/manifests}/${target}"
        if $tmp; then
            output_dir="${to_dir:-tmp/manifests}/${target}"
        fi
        local actions=$(add-commas ${action_list:-update,render})
        info "running actions $actions for $target"
        run_actions $actions
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
