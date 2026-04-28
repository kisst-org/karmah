# target: run function for all targets

targets::declare-vars() {
    declare -g target_subdirs=""
}

targets::init-module() {
    add-action pt print-target "print all target paths"
    add-command run run-flows "" "run one or more (flow) actions for all targets"
    help_level=expert
    add-parse-option s subdir dir "add subdir to list of subdirs (can be comma separated list)"
    default_command=run-flows
}

parse-option-subdir() { target_subdirs+=" $2"; argparse_parse_count=2; }
run-action-print-target() { echo $target_path; }
run-command-run-flows()   { run-func-for-targets run-flow-actions; }

run-func-for-targets() {
    local target_func=$1
    if [[ -z ${target_paths:-} ]]; then
        log-warn targets "no target paths provided, but needed for $target_func"
        return 0
    fi
    local path
    for path in $target_paths; do
        if [[ -z ${target_subdirs:-} ]]; then
            local target_path=${path%%/}
            local target_name=$target_path
            $target_func
        else
            for sd in ${target_subdirs//,/ }; do
                local target_path=${path%%/}/$sd
                local target_name=$target_path
                $target_func
            done
        fi
    done
}
