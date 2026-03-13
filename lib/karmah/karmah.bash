# karmah: do stuff based on *.karmah file

karmah-init-climah-vars() {
    declare -g local_vars="karmah_type target_name"
    declare -g local_arrays=""
    declare -g karmah_paths=""
    declare -g default_karmah_type=empty
    climah_prog=karmah
    #climah_full_help_function=karmah-show-full-help
    }

karmah-init-climah-module() {
    help-add-topic ver version  karmah-show-version "show version of karmah"
    command=render
    help_level=expert
    options-add-value-opt K force-karmah-type typ "force to use another karmah_type"
    local_arrays+=" custom_flow"
    local_vars+=" run_pre_flow"
}

empty-karmah-init-target() { verbose using empty karmah_type initializer; }

add-karmah-action() {
    local short=$1 name=$2 summary="$3"
    commands-register-func "$short" "$name" run-for-all-karmah-paths $name
    help-add-item action "$short" "$name" "" "$summary"
}
# run-karmah-flow-for-all-target-paths
# run-karmah-action-for-all-target-paths
run-for-all-karmah-paths() {
    local action_flow=$1
    if [[ -z ${target_paths:-} ]]; then
        warn "no target paths provided, but needed for action $action_flow"
        help-show-summary
        return 0
    fi
    for target_path in $target_paths; do
        run-karmah-path $action_flow  #$target_path
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
    #local target_name=$(dirname $karmah_file)
    if [[ -f "${karmah_file}" ]]; then
        # cleanup of any vars that might have been set with previous file
        debug clearing $local_vars $local_arrays
        unset $local_vars $local_arrays
        declare $local_vars
        declare -A $local_arrays
        karmah_dir=$(dirname $karmah_file)
        common_dir=$(dirname $karmah_dir)/common
        debug sourcing $karmah_file
        source ${karmah_file}
        common-karmah
        output_dir="${to_dir:-tmp/manifests}/${target_name}"
        if $tmp; then
            output_dir="${to_dir:-tmp/manifests}/${target_name}"
        fi
        run-action-flow $action_flow
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
    ${karmah_type}-karmah-init-target
}

karmah-show-full-help() {
cat <<EOF
karmah: Kubernetes Application Rendered MAnifest Helper (version $karmah_version)

Description:
  karmah helps to enforce the rendered manifest pattern for targets
  Each target is defined in a karmah file, which defines various options, like:
  - rendering method to use (e.g. helm, kustomize)
  - rendering parameters, e.g. helm charts and value file
  - deployment method, e.g helm intstall, kapp deploy, kubectl apply
  - kubernetes info, e.g. kubeconfig, context and namespace
  - helper info, e.g. how to inspect, scale and change versions

Usage:
  ${climah_prog_name} [ option | command/flow | target ]...

$(help-show-summary)

Targets:
  Each path defines an application definition, that will be sourced,
  This can either be a file, or a directory that contains exactly 1 file with a name '*.karmah'.
  When one or more --subdirs are specfied, these will be append to the path

Note:
  Options, commands/actions and paths can be mixed freely.
  If multiple commands are given, only last command will be used.
EOF
}

karmah-show-version() { echo karmah version: $karmah_version; }
