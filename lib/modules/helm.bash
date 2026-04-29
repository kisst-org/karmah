
helm::init-module() {
    add-module-help "actions to work with helm"
    add-render-action hd helm-diff           "run diff for target vs helm deployed manifests"
    add-render-action "" helm-upgrade        "run helm upgrade --install for target"
    add-karmah-action "hpv" helm-print-value  "print the value of a path in  helm values"
    help_level=expert
    add-render-action "" helm-get-diff       "old name for helm-diff (deprecated)"
    add-render-action "" helm-plugin-diff    "run helm diff plugin for target"
    add-render-action "" helm-install        "deprecated: run helm upgrade --install for target"
    add-render-action "" helm-uninstall      "run helm uninstall for target"
    add-render-action "" helm-pull           "pull a helm chart from a remote repo to helm/charts"
    add-render-action "" helm-get-manifests  "download helm manifests from cluster"
    add-value-option H force-helm-chart  chrt  "force to use a specific helm chart"
    add-flag-option "" force-pull "force pulling a helm chart if already exists" # TODO:

    set-action-pre-flow load-karmah,update,render,helm-diff,ask         helm-install
    set-action-pre-flow load-karmah,update,render,helm-diff,ask         helm-upgrade
    set-action-pre-flow load-karmah,update,render,helm-diff-delete,ask  helm-uninstall

    add-karmah-var path "the path to show from helm values"

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
        *) log-error helm "unknow helm_chart_location $helm_chart_location"; exit 1;;
    esac
}

run-helm() {
    local subcmd=$1 args=${@:2}
    : ${helm_release:=$(basename $target_name)}
    local opts="$(helm-cluster-options)"
    opts+=" $helm_release"
    opts+=" $(calc-helm-chart-options)"
    if [[ ! -z ${helm_post_renderer:-} ]]; then
        opts+=" --post-renderer ${helm_post_renderer}"
    fi
    local f; for f in ${helm_value_files[@]}; do
        opts+=" -f ${f}";
    done
    run-verbose-cmd helm $subcmd $opts $args
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
    run-helm diff upgrade
}

run-action-helm-upgrade() {
    log-info helm "running helm-upgrade for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    run-helm upgrade --install ${helm_atomic_wait}
}

run-action-helm-install() {
    log-info helm "running helm-install for $target_name"
    run-helm install --create-namespace
}

run-action-helm-uninstall() {
    log-info helm "running helm-uninstall for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm uninstall"
    run-helm uninstall ${helm_atomic_wait}
}

run-action-helm-get-manifests() {
    local release=${helm_release:=$(basename $target_name)}
    log-info helm "getting manifests from helm release ${release} in namespace $kube_namespace to ${output_dir}"
    run-cmd-from-action verbose rm -rf ${output_dir}
    run-cmd-from-action verbose mkdir -p ${output_dir}
    run-verbose-cmd helm get manifest $release $(helm-cluster-options) \| split-yaml-docs-into-files
}

run-action-helm-get-diff() { run-action-helm-diff; } # TODO: deprecated
run-action-helm-diff() {
    # do a check status to see if the release exists
    local release=${helm_release:=$(basename $target_name)}
    log-debug helm "checking for helm release ${release} in namespace $kube_namespace"
    local cmd="helm status $release $(helm-cluster-options)"
    log-verbose cmd.helm "$cmd"
    local tmp_status_failed=false
    # Note: not using log-verbose-cmd, so is run, even in dry-run
    $cmd >/dev/null || tmp_status_failed=true
    if $tmp_status_failed ; then
        log-info helm "helm release $helm_release does not yet exist in namespace $kube_namespace, skipping helm-diff"
        return 0;
    fi

    local render_dir=tmp/manifests/${target_name}
    local get_dir=${with_dir:-tmp/get}/${target_name}
    local output_dir=$render_dir
    local output_dir=$get_dir
    run-action-helm-get-manifests
    log-info helm "comparing ${target_name}: helm-get ${get_dir} with rendered ${render_dir}"
    # The sed script is to make missing or added manifests stand out more clearly
    run-cmd-from-action verbose diff -r $get_dir $render_dir | sed 's/^Only in /<> ONLY IN /' || true
}

run-action-helm-print-value() {
    use-karmah-var path
    helm-get-path-value $path
}

render-helm() {
    used_files+=" ${helm_value_files[@]}"
    run-helm template \| split-yaml-docs-into-files
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
