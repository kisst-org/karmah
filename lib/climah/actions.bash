# raftah: run actions for all targets

init_climah_vars_actions() {
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
    declare -gA target_function=()
}

init_climah_module_actions() {
    #add_command "forall" "run actions for all targets"
    command=print-target
    add-command run run-actions ""   "run actions forall targets"
    add-command ""  actions show-actions "show available actions"
    add-target-action pt print-target "print all targets"
    help_level=expert
    add-list-option s subdir   dir   "add subdir to list of subdirs (can be comma separated list)"
    add-flag-option T tmp    "render to tmp/manifests (obsolete, tmp is already default), do not commit"
}

add-target-action() { add-action run-for-all-target-paths "${@}"; }
add-action() {
    debug adding action: "${@}"
    local cmd_func=$1
    local short=$2
    local name=$3
    parse_arg_func[$name]=parse-action
    shift 3
    local help="$*"
    if [[ ${enable_short_commands:-true} && ! -z $short ]]; then
        local s
        for s in ${short//,/ }; do
            arg_alias[$s]=$name
            action_alias[$s]=$name
        done
        help+=" ($short)"
    fi
    add-command "$short" "$name" $cmd_func "$help"
    action_help[$name]="$help"
    action_level[$name]=$help_level
    action_module[$name]=$module
    all_actions+=" $name"
}

#parse-action() {
#    local name=${action_alias[$1]:-$1}
#    action_list+=" ${action_flow[$name]:-$name}"
#}

set-pre-actions() {
    local name actions="$1"
    shift
    for name in "${@//,/ }"; do
        action_flow[$name]=$actions,$name
    done

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

run-action-print-target() { echo $target_path; }

run-for-all-target-paths() {
    target_func=${target_function[$command]:-run-action-$command}
    for target_path in $target_paths; do
        $target_func $target_path
    done
}
