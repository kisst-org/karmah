
init_bash_module_helm() {
    use_module render
    add_action helm-install "run helm upgrade --install for target"
    add_action helm-uninstall "run helm uninstall for target"
    global_vars+=" helm_template_command"
    global_vars+=" helm_value_files"
    global_vars+=" helm_charts"
    global_vars+=" helm_install_command"
    global_vars+=" helm_atomic_wait"
    global_vars+=" helm_release"
    global_vars+=" helm_wait_timeout"
    global_arrays+="helm_update_version_path helm_update_replicas_path"
}

add_optional_helm_values_file() {
    local f=($1)
    if [[ -f $f ]]; then
        debug adding values file $f
        helm_value_files+=("$f")
    else
        debug skipping values file $f
    fi
}

init_helm_vars() {
    local parent_dir=$(dirname "$karmah_dir")
    add_optional_helm_values_file "$common_dir/values*.yaml"
    add_optional_helm_values_file "$karmah_dir/values*.yaml"
}

calc_helm_command() {
    local chart=$1
    shift
    local cmd=$@
    local f
    : ${helm_release:=$(basename $target)}
    for f in ${helm_value_files[@]}; do
        cmd+=" -f ${f}";
    done
    cmd+=" $helm_release"
    cmd+=" --namespace $namespace"
    cmd+=" $chart"
    echo $cmd
}

run_helm_forall_charts() {
    run_cmd=$1
    shift
    local base_cmd=${@}
    for ch in ${helm_charts//,/ }; do
        local chart=${ch//@*}
        if [[ $ch == $chart ]]; then
            local helm_cmd=$(calc_helm_command $chart ${base_cmd})
            used_files+=" $ch"
            $run_cmd "$helm_cmd"
        else
            local helm_cmd=$(calc_helm_command $chart $base_cmd})
            local repo=${ch//*@}
            $run_cmd "$helm_cmd --repo $repo --version $chart_version"
        fi
    done
}

run_action_helm-install() {
    : ${helm_atomic_wait:=--wait --atomic --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm upgrade --install ${helm_atomic_wait} --create-namespace $(helm_cluster_options)"
    run_helm_forall_charts "verbose_cmd" ${helm_install_command:-$default_cmd}
}

run_action_helm-uninstall() {
    : ${helm_atomic_wait:=--wait --atomic --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm uninstall ${helm_atomic_wait} $(helm_cluster_options)"
    run_helm_forall_charts "verbose_cmd" ${helm_install_command:-$default_cmd}
}


render_helm() {
    local default_cmd="helm template"
    local f
    used_files+=" ${helm_value_files[@]}"
    run_helm_forall_charts "verbose_pipe split_into_files" ${helm_template_command:-$default_cmd}
}

update_version_helm() {
    local res
    local val_file=($karmah_dir/values*.yaml)
    for res in $(calc_resource_names); do
        verbose updating $res version to $update_version
        verbose_cmd yq -i "${helm_update_version_path[$res]}=\"$update_version\"" $val_file
    done
}

update_replicas_helm() {
    local res
    local val_file=($karmah_dir/values*.yaml)
    for res in $(calc_resource_names); do
        local repl=${kube_replicas:-default}
        if [[ $repl == default ]]; then
            repl=${kube_default_replicas[$res]}
        fi
        verbose updating $res replicas to $repl
        verbose_cmd yq -i "${helm_update_replicas_path[$res]}=\"$repl\"" $val_file
    done
}

helm_cluster_options() {
    local cl=${kube_cluster}
    local cfg=${kube_config_map[$cl]:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+=" --kube-context ${kube_context_map[$cl]}"
    echo $opt
}
