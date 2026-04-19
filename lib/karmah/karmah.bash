# karmah: do stuff based on *.karmah file

karmah::declare-vars() {
    declare -g local_vars="karmah_type target_name"
    declare -g default_karmah_type=empty
}

karmah::init-climah-module() {
    climah_prog=karmah
    add-help-topic ver version  karmah-show-version "show version of karmah"
    default_action=render
    add-action lk load-karmah "load *.karmah init file(s)"
    help_level=expert
    add-value-option K force-karmah-type typ "force to use another karmah_type"
}

empty::init-target() { verbose using empty karmah_type initializer; }


add-karmah-action() {
    add-action "${@}"
    set-action-pre-flow load-karmah "$2"
}

run-action-load-karmah() {
    if [[ -f $target_path ]]; then
        karmah_file=$target_path
    elif [[ -d ${target_path:-} ]]; then
        karmah_file=($target_path/*.karmah) # use array for globbing
    else
        info "skipping $target_path"
        # TODO: warn, error or skip_flow
        return 0
    fi
    load-karmah-file
}


load-karmah-file() {
    declare -g karmah_type
    if [[ -f "${karmah_file}" ]]; then
        # cleanup of any vars that might have been set with previous file
        debug clearing $local_vars
        unset $local_vars
        declare -g $local_vars
        karmah_dir=$(dirname $karmah_file)
        common_dir=$(dirname $karmah_dir)/common
        debug sourcing $karmah_file
        source ${karmah_file}
        common-karmah
        output_dir="${to_dir:-tmp/manifests}/${target_name}"
        if $tmp; then
            output_dir="${to_dir:-tmp/manifests}/${target_name}"
        fi
    else
        info skipping $karmah_file
    fi
}

common-karmah() {
    used_files=${karmah_dir}
    local common_karmah_file=($common_dir/common*.karmah)
    if [[ -f $common_karmah_file ]]; then
        debug sourcing $common_karmah_file
        source $common_karmah_file
    fi
    karmah_type=${force_karmah_type:-${karmah_type:-$default_karmah_type}}
    ${karmah_type}::init-target
}

karmah-show-version() { echo karmah version: $karmah_version; }
