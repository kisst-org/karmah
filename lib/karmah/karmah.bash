# karmah: do stuff based on *.karmah file

karmah::declare-vars() {
    declare -g local_vars="karmah_type target_name"
    declare -g default_karmah_type=empty
}

karmah::init-climah-module() {
    climah_prog=karmah
    #climah_full_help_function=karmah-show-full-help
    help-add-topic ver version  karmah-show-version "show version of karmah"
    default_command_to_run=run-func-for-targets
    target_func=run-karmah-path
    default_action_to_run=render
    help_level=expert
    add-value-option K force-karmah-type typ "force to use another karmah_type"
}

empty-karmah-init-target() { verbose using empty karmah_type initializer; }

add-karmah-action() { add-action run-karmah-path "${@}"; }

run-karmah-path() {
    if [[ -f $target_path ]]; then
        karmah_file=$target_path
        run-karmah-file
    elif [[ -d ${target_path:-} ]]; then
        karmah_file=($target_path/*.karmah) # use array for globbing
        run-karmah-file
    else
        info "skipping $target_path"
    fi
}

run-karmah-file() {
    local karmah_type
    #local target_name=$(dirname $karmah_file)
    if [[ -f "${karmah_file}" ]]; then
        # cleanup of any vars that might have been set with previous file
        debug clearing $local_vars
        unset $local_vars
        declare $local_vars
        karmah_dir=$(dirname $karmah_file)
        common_dir=$(dirname $karmah_dir)/common
        debug sourcing $karmah_file
        source ${karmah_file}
        common-karmah
        output_dir="${to_dir:-tmp/manifests}/${target_name}"
        if $tmp; then
            output_dir="${to_dir:-tmp/manifests}/${target_name}"
        fi
        run-action-flow
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
empty::init-target() { verbose "using empty karmah_type"; }

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
  When one or more --subdir's are specfied, these will be appended to the path.

Note:
  Options, commands/actions and paths can be mixed freely.
  If multiple commands are given, only last command will be used.
EOF
}

karmah-show-version() { echo karmah version: $karmah_version; }
