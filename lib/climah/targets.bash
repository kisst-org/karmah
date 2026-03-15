# target: run function for all targets

targets::init-climah-vars() {
    declare -gA target_func
    declare -g target_subdirs=""
}

targets::init-climah-module() {
    # TODO: commands-add rsa run-single-actions "" "run isolated actions forall targets"
    add-target-action pt print-target "print all target paths"
    help_level=expert
    options-add s subdir dir "add subdir to list of subdirs (can be comma separated list)"
    commands-add rf run-flow run-func-for-targets "run flow of one or more actions for all targets"
    #commands-add rsa run-single-action run-single-action-for-all-targets "run isolated actions for all targets"
}

parse-option-subdir() { target_subdirs+=" $2"; argparse_parse_count=2; }

add-target-action() { add-action run-for-all-target-paths "${@}"; }

run-action-print-target() { echo $target_path; }

run-func-for-targets() {
    if [[ -z ${target_paths:-} ]]; then
        warn "no target paths provided, but needed for action $action_flow"
        help-show-summary
        return 0
    fi
    local path
    for path in $target_paths; do
        if [[ -z ${target_subdirs:-} ]]; then
            local target_path=${path%%/}
            local target_name=$target_path
            $target_func $target_path
        else
            for sd in ${target_subdirs//,/ }; do
                local target_path=${path%%/}/$sd
                local target_name=$target_path
                $target_func $target_path
            done
        fi
    done
}
