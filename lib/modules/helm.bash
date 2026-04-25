
helm::init-climah-module() {
    add-module-help "actions to work with helm"
    help_level=expert
    add-render-action hd helm-diff           "run diff for target vs helm deployed manifests"
    add-render-action "" helm-get-diff       "old name for helm-diff (deprecated)"
    add-render-action hD helm-plugin-diff    "run helm diff plugin for target"
    add-render-action "" helm-upgrade        "run helm upgrade --install for target"
    add-render-action "" helm-install        "deprecated: run helm upgrade --install for target"
    add-render-action "" helm-uninstall      "run helm uninstall for target"
    add-render-action "" helm-pull           "pull a helm chart from a remote repo to helm/charts"
    add-render-action "" helm-get-manifests  "download helm manifests from cluster"
    add-value-option H force-helm-chart  chrt  "force to use a specific helm chart"
    add-flag-option "" force-pull "force pulling a helm chart if already exists" # TODO:

    set-action-pre-flow load-karmah,update,render,helm-diff,ask         helm-install
    set-action-pre-flow load-karmah,update,render,helm-diff,ask         helm-upgrade
    set-action-pre-flow load-karmah,update,render,helm-diff-delete,ask  helm-uninstall

    local_vars+=" helm_template_command"
    local_vars+=" helm_value_files"
    local_vars+=" helm_chart"
    local_vars+=" helm_chart_repo"
    local_vars+=" helm_chart_version"
    local_vars+=" helm_chart_location"
    local_vars+=" helm_install_command"
    local_vars+=" helm_atomic_wait"
    local_vars+=" helm_release"
    local_vars+=" helm_wait_timeout"
    local_vars+=" helm_post_renderer"
}

add-optional-helm-values-file() {
    local f=($1)
    if [[ -f $f ]]; then
        log-debug helm "adding values file $f"
        helm_value_files+=("$f")
    else
        log-debug helm "skipping values file $f"
    fi
}

helm-calc-command() {
    local cmd="$*"
    local chart=$(calc-helm-chart-options)
    local f
    : ${helm_release:=$(basename $target_name)}
    cmd+=" $helm_release"
    cmd+=" $chart"
    for f in ${helm_value_files[@]}; do
        cmd+=" -f ${f}";
    done
    if [[ ! -z ${helm_post_renderer:-} ]]; then
        cmd+=" --post-renderer ${helm_post_renderer}"
    fi
    echo $cmd
}

calc-helm-chart-options() {
    case ${helm_chart_location:-local} in
        local)   echo $helm_chart;;
        remote)  echo "$helm_chart_name --repo $helm_chart_repo  --version helm_chart_version";;
        pulled)  echo helm/charts/$helm_chart_name-$helm_chart_version ;;
        *) error "unknow helm_chart_location $helm_chart_location"; exit 1;;
    esac
}

helm-run() {
    local verbose_runner_cmd=$1; shift
    local base_cmd=${@}
    if [[ ! -z ${force_helm_chart:-} ]]; then
        log-verbose helm "overriding original helm chart $helm_chart with ${force_helm_chart}"
        helm_chart=${force_helm_chart}
        helm_chart_location=local # TODO: other locatiom,repo,version?
    fi
    local helm_cmd="$(helm-calc-command ${base_cmd})"
    # TODO: used_files+=" $ch"
    # This does not work nicely with git-restore, when testing a template
    # better issur a warning if a helm chart is modified when commiting
    $verbose_runner_cmd "$helm_cmd"
}

run-action-helm-pull() {
    local dir=helm/charts/$helm_chart_name-$helm_chart_version
    log-info helm "running helm-pull for $helm_chart_name $helm_chart_version to $dir"
    if [[ -d $dir ]]; then
        if ${force_pull:-false}; then
            log-verbose helm "$dir already exists, removing it"
            run-cmd-from-action verbose rm -rf $dir
        else
            log-verbose helm "$dir already exists, skipping helm-pull (use --force-pull to override)"
            return 0
        fi
    fi
    local tarfile=tmp/helm-charts/$helm_chart_name-$helm_chart_version.tgz
    if [[ -f $tarfile && ${force_pull:-false} == false ]]; then
        log-verbose helm "$tarfile already exists, skipping helm-pull (use --force-pull to override)"
    else
        run-cmd-from-action verbose mkdir -p $(dirname $tarfile)
        local cmd="helm pull --repo ${helm_chart_repo} ${helm_chart_name} --version ${helm_chart_version} --destination $(dirname $tarfile)"
        run-cmd-from-action verbose ${cmd}
    fi
    run-cmd-from-action verbose mkdir -p $dir
    run-cmd-from-action verbose tar xfz $tarfile --dir $dir --strip-components 1
}


run-action-helm-plugin-diff() {
    log-info helm "running helm-plugin-diff for $target_name"
    local default_cmd="helm diff upgrade $(helm-cluster-options)"
    helm-run run-cmd-from-action verbose ${helm_install_command:-$default_cmd}
}

run-action-helm-upgrade() {
    log-info helm "running helm-upgrade for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm upgrade --install ${helm_atomic_wait} --create-namespace $(helm-cluster-options)"
    helm-run run-cmd-from-action verbose ${helm_install_command:-$default_cmd}
}

run-action-helm-install() {
    log-info helm "running helm-install for $target_name"
    local default_cmd="helm install --create-namespace $(helm-cluster-options)"
    helm-run run-cmd-from-action verbose ${helm_install_command:-$default_cmd}
}

run-action-helm-uninstall() {
    log-info helm "running helm-uninstall for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm $(helm-cluster-options) uninstall"
    helm-run run-cmd-from-action verbose ${helm_install_command:-$default_cmd}
}

run-action-helm-get-manifests() {
    local release=${helm_release:=$(basename $target_name)}
    log-info helm "getting manifests from helm release ${release} in namespace $kube_namespace to ${output_dir}"
    run-cmd-from-action verbose rm -rf ${output_dir}
    run-cmd-from-action verbose mkdir -p ${output_dir}
    local cmd="helm $(helm-cluster-options) get manifest $release --namespace $kube_namespace"
    verbose-pipe split-yaml-docs-into-files $cmd
}

run-action-helm-get-diff() { run-action-helm-diff; } # TODO: deprecated
run-action-helm-diff() {
    # do a check status to see if the release exists
    local release=${helm_release:=$(basename $target_name)}
    log-debug helm "checking for helm release ${release} in namespace $kube_namespace"
    local cmd="helm $(helm-cluster-options) status $release --namespace $kube_namespace"
    log-verbose helm "   $cmd"
    local tmp_status_failed=false
    $cmd >/dev/null || tmp_status_failed=true
    if $tmp_status_failed ; then
        log-info helm "helm release $helm_release does not yet exist in namespace $kube_namespace, skipping helm-diff"
        return 0;
    fi

    local render_dir=tmp/manifests/${target_name}
    local get_dir=${with_dir:-tmp/get}/${target_name}
    local output_dir=$render_dir
    #run-action-update
    #run-action-render
    local output_dir=$get_dir
    run-action-helm-get-manifests
    log-info helm "comparing ${target_name}: helm-get ${get_dir} with rendered ${render_dir}"
    # The sed script is to make missing or added manifests stand out more clearly
    run-cmd-from-action verbose diff -r $get_dir $render_dir | sed 's/^Only in /<> ONLY IN /' || true
}


render-helm() {
    local default_cmd="helm template"
    local f
    used_files+=" ${helm_value_files[@]}"
    helm-run "verbose-pipe split-yaml-docs-into-files" ${helm_template_command:-$default_cmd}
}

# this function will iterate over all helm_value_files
# and get the latest of a certain path
helm-get-path-value() {
    local path=$1
    local f result
    if [[ -f ${helm_chart}/values.yaml ]]; then
        # TODO: this only works for local charts
        local helm_chart_values_file=${helm_chart}/values.yaml
    fi
    for f in ${helm_chart_values_file:-} ${helm_value_files[@]}; do
        local val=$(yq $path $f)
        if [[ $val != null ]]; then result=$val; fi
    done
    echo $result
}

helm-update-value-path() {
    local path="$1" value="$2"
    local val_file=${helm_value_files[@]:(-1)}
    log-verbose helm "updating $path to \"$value\""
    run-cmd-from-action verbose yq -i $path=\"$value\"   $val_file
}

helm-cluster-options() {
    local cfg=${kube_config:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+=" --kube-context ${kube_context}"
    opt+=" --namespace $kube_namespace"
    echo $opt
}
