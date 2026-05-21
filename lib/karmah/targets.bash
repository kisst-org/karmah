# target: run function for all targets

targets::declare-vars() {
    declare -g target_subdirs=""
}

targets::init-module() {
    declare-action pt print-target "print all target paths"
    help_level=expert
    add-func-option s subdir dir "add subdir to list of subdirs (can be comma separated list)"
}

parse-if-target() {
    local arg=${1}
    if [[ -f ${arg} ]]; then
        target_paths+=" ${arg}"
        argparse_parse_count=1
    elif [[ -d ${arg} ]]; then
        target_paths+=" ${arg%/}" # remove a possible trailing /
        argparse_parse_count=1
    fi
}

option::subdir() { target_subdirs+=" $2"; argparse_parse_count=2; }
action::print-target() { echo $target_path; }

run-func-for-targets() {
    local target_func=$1
    # : ${target_paths:=${default_target_paths:-}}
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
