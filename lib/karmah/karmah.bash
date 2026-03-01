# karmah: do stuff based on *.karmah file

init_climah_vars_karmah() {
    declare -g local_vars="karmah_type target karmah_func"
    declare -g local_arrays=""
    declare -g karmah_paths=""
    }

init_climah_module_karmah() {
    command=render
    help_level=expert
    add-value-option K force-karmah-type typ "force to use another karmah_type"
    local_arrays+=" custom_flow"
    local_var+=" run_pre_flow"
}

init_karmah_type_basic() {
    verbose using empty karmah_type initializer
}

add-karmah-action() { add-action run-for-all-karmah-paths "${@}"; }
run-for-all-karmah-paths() {
    for target_path in $target_paths; do
        run-karmah-path #$target_path
    done
}

run-karmah-path() {
    if [[ -f $target_path ]]; then
        karmah_file=$target_path
        run-karmah-file
    elif [[ -z ${subdir:-} ]]; then
        karmah_file=($target_path/*.karmah) # use array for globbing
        run-karmah-file
    else
        for sd in ${subdir//,/ }; do
            karmah_file=($target_path/$sd/*.karmah)  # use array for globbing
            run-karmah-file
        done
    fi
}

run-karmah-file() {
    local karmah_type
    local actions=$(add-commas ${action_flow[$command]:-$command})
    #local target_name=$(dirname $karmah_file)
    if [[ -f "${karmah_file}" ]]; then
        # cleanup of any vars that might have been set with previous file
        debug clearing $local_vars $local_arrays
        unset $local_vars $local_arrays
        declare $local_vars
        declare -A $local_arrays
        debug sourcing $karmah_file
        source ${karmah_file}
        common-karmah
        output_dir="${to_dir:-tmp/manifests}/${target_name}"
        if $tmp; then
            output_dir="${to_dir:-tmp/manifests}/${target_name}"
        fi
        info "running actions $actions for $target_name"
        run-actions $actions
    else
        info skipping $karmah_file
    fi
}

common-karmah() {
    karmah_dir=$(dirname $karmah_file)
    common_dir=$(dirname $karmah_dir)/common
    used_files=${karmah_dir}
    local common_karmah_file=($common_dir/common*.karmah)
    if [[ -f $common_karmah_file ]]; then
        debug sourcing $common_karmah_file
        source $common_karmah_file
    fi
    if [[ ! -z ${karmah_func:-} ]]; then
        # TODO: force-karmah-func?
        $karmah_func
    elif [[ ! -z ${karmah_type:-} ]]; then
        #warn karmah_type is deprecated, use karmah_func instead
        karmah_type=${force_karmah_type:-${karmah_type:-basic}}
        init_karmah_type_${karmah_type}
    fi
}
