
init_climah_module_helm() {
    help_level=expert
    add-karmah-action hD helm-diff           "run helm diff plugin for target"
    add-karmah-action "" helm-upgrade        "run helm upgrade --install for target"
    add-karmah-action "" helm-install        "deprecated: run helm upgrade --install for target"
    add-karmah-action "" helm-uninstall      "run helm uninstall for target"
    add-karmah-action "" helm-get-manifests  "download helm manifests from cluster"
    add-karmah-action hd helm-get-diff       "run diff for target vs helm deployed manifests"
    add-value-option H force-helm-chart  chrt  "force to use a specific helm chart"

    set-pre-actions update,render                       helm-diff
    set-pre-actions update,render,kube-diff,ask         helm-install
    set-pre-actions update,render,kube-diff,ask         helm-upgrade
    set-pre-actions update,render,kube-diff-delete,ask  helm-uninstall

    local_vars+=" helm_template_command"
    local_vars+=" helm_value_files"
    local_vars+=" helm_chart"
    local_vars+=" helm_install_command"
    local_vars+=" helm_atomic_wait"
    local_vars+=" helm_release"
    local_vars+=" helm_wait_timeout"
    local_vars+=" helm_post_renderer"
    local_arrays+=" helm_update_version_path helm_update_replicas_path"
    add-module-help "actions to work with helm"
}
helm-show-help() { help-show-module helm; }


helm-add-optional-values-file() {
    local f=($1)
    if [[ -f $f ]]; then
        debug adding values file $f
        helm_value_files+=("$f")
    else
        debug skipping values file $f
    fi
}

init_helm_vars() {
    helm-add-optional-values-file "$common_dir/values*.yaml"
    helm-add-optional-values-file "$karmah_dir/values*.yaml"
}

calc_helm_command() {
    local chart=$1
    shift
    local cmd=$@
    local f
    : ${helm_release:=$(basename $target_name)}
    for f in ${helm_value_files[@]}; do
        cmd+=" -f ${f}";
    done
    cmd+=" $helm_release"
    cmd+=" --namespace $kube_namespace"
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
        verbose overriding original helm chart $helm_chart with ${force_helm_chart}
        helm_chart=${force_helm_chart}
    fi
    for ch in ${helm_chart//,/ }; do
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
    info "running helm-diff for $target_name"
    local default_cmd="helm diff upgrade $(helm_cluster_options)"
    run_helm_forall_charts "verbose-cmd" ${helm_install_command:-$default_cmd}
}

run-action-helm-upgrade() {
    info "running helm-upgrade for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm upgrade --install ${helm_atomic_wait} --create-namespace $(helm_cluster_options)"
    run_helm_forall_charts "verbose-cmd" ${helm_install_command:-$default_cmd}
}

run-action-helm-install() { run-action-helm-upgrade; }

run-action-helm-uninstall() {
    info "running helm-uninstall for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm uninstall ${helm_atomic_wait} $(helm_cluster_options)"
    run_helm_forall_charts "verbose-cmd" ${helm_install_command:-$default_cmd}
}

run-action-helm-get-manifests() {
    local release=${helm_release:=$(basename $target_name)}
    info getting manifests from helm release ${release} in namespace $kube_namespace to ${output_dir}
    verbose-cmd rm -rf ${output_dir}
    verbose-cmd mkdir -p ${output_dir}
    local cmd="helm $(helm_cluster_options) get manifest $release --namespace $kube_namespace"
    verbose-pipe split_into_files $cmd
}

run-action-helm-get-diff() {
    # do a check status to see if the release exists
    local release=${helm_release:=$(basename $target_name)}
    debug checking for helm release ${release} in namespace $kube_namespace
    local cmd="helm $(helm_cluster_options) status $release --namespace $kube_namespace"
    verbose "   $cmd"
    local tmp_status_failed=false
    $cmd >/dev/null || tmp_status_failed=true
    if $tmp_status_failed ; then
        info helm release $helm_release does not yet exist in namespace $kube_namespace, skipping helm-get-diff
        return 0;
    fi

    local render_dir=tmp/manifests/${target_name}
    local get_dir=${with_dir:-tmp/get}/${target_name}
    local output_dir=$render_dir
    run-action-update
    run-action-render
    local output_dir=$get_dir
    run-action-helm-get-manifests
    info comparing ${target_name}: helm-get ${get_dir} with rendered ${render_dir}
    verbose-cmd diff -r $get_dir $render_dir || true
}


render_helm() {
    local default_cmd="helm template"
    local f
    used_files+=" ${helm_value_files[@]}"
    run_helm_forall_charts "verbose-pipe split_into_files" ${helm_template_command:-$default_cmd}
}

# this function will iterate over all helm_value_files
# and get the latest of a certain path
helm-get-path-value() {
    local path=$1
    local f result
    for f in ${helm_value_files[@]}; do
        local val=$(yq $path $f)
        if [[ $val != null ]]; then result=$val; fi
    done
    echo $result
}

helm-update-value-path() {
    local path="$1" value="$2"
    local val_file=${helm_value_files[@]:(-1)}
    verbose updating $path to \"$value\"
    verbose-cmd yq -i $path=$value $val_file
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
        verbose-cmd yq -i "${helm_update_replicas_path[$res]}=\"$repl\"" $val_file
    done
}

helm_cluster_options() {
    local cfg=${kube_config:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+=" --kube-context ${kube_context}"
    echo $opt
}
