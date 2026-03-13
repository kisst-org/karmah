# raftah: run actions for all targets

targets-init-climah-vars() {
    declare -gA target_function=()
}

targets-init-climah-module() {
    #add_command "forall" "run actions for all targets"
    command=print-target
    # TODO: commands-add rsa run-single-actions "" "run isolated actions forall targets"
    add-target-action pt print-target "print all target paths"
    help_level=expert
    options-add s subdir dir  "add subdir to list of subdirs (can be comma separated list)"
}

parse-option-subdir() { subdir+=" $2"; argparse_parse_count=2; }

add-target-action() { add-action run-for-all-target-paths "${@}"; }

run-action-print-target() { echo $target_path; }

# run-flow-for-all-target-paths
# run-action-for-all-target-paths
run-for-all-target-paths() {
    target_func=${target_function[$command]:-run-action-$command}
    for target_path in $target_paths; do
        local target_name=$target_path
        $target_func $target_path
    done
}
