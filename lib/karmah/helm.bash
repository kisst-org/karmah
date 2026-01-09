
init_climah_module_helm() {
    help_level=expert
    add-action hd helm-diff      update,render "run helm diff for target"
    add-action "" helm-upgrade   update,render "run helm upgrade --install for target"
    add-action "" helm-install   update,render "deprecated: run helm upgrade --install for target"
    add-action "" helm-uninstall update,render "run helm uninstall for target"
    add-value-option H force-helm-chart  chrt  "force to use a specific helm chart"

    set-pre-actions update,render                       helm-diff
    set-pre-actions update,render,kube-diff,ask         helm-install
    set-pre-actions update,render,kube-diff,ask         helm-upgrade
    set-pre-actions update,render,kube-diff-delete,ask  helm-uninstall

    local_vars+=" helm_template_command"
    local_vars+=" helm_value_files"
    local_vars+=" helm_charts"
    local_vars+=" helm_install_command"
    local_vars+=" helm_atomic_wait"
    local_vars+=" helm_release"
    local_vars+=" helm_wait_timeout"
    local_vars+=" helm_post_renderer"
    local_arrays+=" helm_update_version_path helm_update_replicas_path"
}

add-optional_helm_values_file() {
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
    add-optional_helm_values_file "$common_dir/values*.yaml"
    add-optional_helm_values_file "$karmah_dir/values*.yaml"
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
    if [[ ! -z ${helm_post_renderer:-} ]]; then
        cmd+=" --post-renderer ${helm_post_renderer}"
    fi
    echo $cmd
}

run_helm_forall_charts() {
    run_cmd=$1
    shift
    local base_cmd=${@}
    if [[ ! -z ${force_helm_chart:-} ]]; then
        verbose overriding original helm chart $helm_charts with ${force_helm_chart}
        helm_charts=${force_helm_chart}
    fi
    for ch in ${helm_charts//,/ }; do
        local chart=${ch//@*}
        if [[ $ch == $chart ]]; then
            local helm_cmd=$(calc_helm_command $chart ${base_cmd})
            # TODO: used_files+=" $ch"
            # This does not work nicely with git-restore, when testing a template
            # better issur a warning if a helm chart is modified when commiting
            $run_cmd "$helm_cmd"
        else
            local helm_cmd=$(calc_helm_command $chart $base_cmd})
            local repo=${ch//*@}
            $run_cmd "$helm_cmd --repo $repo --version $chart_version"
        fi
    done
}

run-action-helm-diff() {
    info "running helm-diff for $target"
    local default_cmd="helm diff upgrade $(helm_cluster_options)"
    run_helm_forall_charts "verbose_cmd" ${helm_install_command:-$default_cmd}
}

run-action-helm-upgrade() {
    info "running helm-upgrade for $target"
    : ${helm_atomic_wait:=--wait --atomic --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm upgrade --install ${helm_atomic_wait} --create-namespace $(helm_cluster_options)"
    run_helm_forall_charts "verbose_cmd" ${helm_install_command:-$default_cmd}
}

run-action-helm-install() { run-action-helm-upgrade; }

run-action-helm-uninstall() {
    info "running helm-uninstall for $target"
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

update_helm_value_path() {
    local path="$1"
    local value="$2"
    local val_file=($karmah_dir/values*.yaml)
    verbose updating $path to \"$value\"
    verbose_cmd yq -i $path=$value $val_file
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
