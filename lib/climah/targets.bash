# raftah: run actions for all targets

targets-init-climah-vars() {
    declare -gA target_function=()
    declare -g target_subdirs=""
}

targets-init-climah-module() {
    # TODO: commands-add rsa run-single-actions "" "run isolated actions forall targets"
    add-target-action pt print-target "print all target paths"
    help_level=expert
    options-add s subdir dir "add subdir to list of subdirs (can be comma separated list)"
    commands-add rf run-flow run-for-all-targets "run flow of one or more actions for all targets"
    commands-add rsa run-single-action run-single-action-for-all-targets "run isolated actions for all targets"
}

parse-option-subdir() { target_subdirs+=" $2"; argparse_parse_count=2; }

add-target-action() { add-action run-for-all-target-paths "${@}"; }

run-action-print-target() { echo $target_path; }

run-single-action-for-all-targets() {
    run_single_action=true
    run-for-all-targets
}
run-for-all-targets() {
    target_func=${target_function[$command]:-run-action-$command}
    for target_path in $target_paths; do
        local target_name=$target_path
        $target_func $target_path
    done
}
