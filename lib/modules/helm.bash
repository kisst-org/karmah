
helm::init-module() {
    add-module-help "actions to work with helm"
    declare-action hd helm-diff           "run diff for target vs helm deployed manifests"
    declare-action "" helm-upgrade        "run helm upgrade --install for target"
    declare-action hpv helm-print-value  "print the value of a path in  helm values"
    help_level=expert
    declare-action "" helm-get-diff       "old name for helm-diff (deprecated)"
    declare-action "" helm-plugin-diff    "run helm diff plugin for target"
    declare-action "" helm-install        "deprecated: run helm upgrade --install for target"
    declare-action "" helm-uninstall      "run helm uninstall for target"
    declare-action "" helm-pull           "pull a helm chart from a remote repo to helm/charts"
    declare-action "" helm-get-manifests  "download helm manifests from cluster"
    declare-action "" helm-import         "annotate the resources as if they are managed by helm"
    #add-value-option H force-helm-chart  chrt  "force to use a specific helm chart"
    add-flag-option "" force-pull "force pulling a helm chart if already exists" # TODO:

    add-karmah-var "" json_path "path" "the path to show from helm values"
    add-flag-option "" bg "run helm-update in the background"

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
    local_vars+=" helm_value_already_updated"
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

calc-helm-chart-options() {
    case ${helm_chart_location:-local} in
        local)   echo $helm_chart;;
        remote)  echo "$helm_chart_name --repo $helm_chart_repo  --version $helm_chart_version";;
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

action::helm-pull() {
    local force_pull=$(get-option-value force-pull false)
    local dir=helm/charts/$helm_chart_name-$helm_chart_version
    log-info helm "helm-pull for $helm_chart_name $helm_chart_version to $dir"
    if [[ -d $dir ]]; then
        if ${force_pull}; then
            log-verbose helm "$dir already exists, removing it"
            run-verbose-cmd rm -rf $dir
        else
            log-verbose helm "$dir already exists, skipping helm-pull (use --force-pull to override)"
            return 0
        fi
    fi
    local tarfile=tmp/helm-charts/$helm_chart_name-$helm_chart_version.tgz
    if [[ -f $tarfile && ${force_pull} == false ]]; then
        log-verbose helm "$tarfile already exists, skipping helm-pull (use --force-pull to override)"
    else
        run-verbose-cmd mkdir -p $(dirname $tarfile)
        local cmd="helm pull --repo ${helm_chart_repo} ${helm_chart_name} --version ${helm_chart_version} --destination $(dirname $tarfile)"
        run-verbose-cmd ${cmd}
    fi
    run-verbose-cmd mkdir -p $dir
    run-verbose-cmd tar xfz $tarfile --dir $dir --strip-components 1
}


action::helm-plugin-diff() {
    run-actions render
    log-info helm "helm-plugin-diff for $target_name"
    run-helm diff upgrade
}

action::helm-upgrade() {
    run-actions helm-diff,ask
    local bg=$(get-option-value bg false)
    log-info helm "helm-upgrade release $helm_release"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    if $bg; then
        climah_wait_for_jobs="fg %%"
        log-info helm "Putting helm upgrade in background job, so commands like kube-log or kube-watch kan run"
        run-helm upgrade --install ${helm_atomic_wait} &
    else
        run-helm upgrade --install --create-namespace ${helm_atomic_wait}
    fi
}

action::helm-install() {
    run-actions helm-diff,ask
    log-info helm "helm-install for $target_name"
    run-helm install --create-namespace
}

action::helm-uninstall() {
    run-actions ask # helm-diff-delete,ask
    log-info helm "helm-uninstall for $target_name"
    : ${helm_atomic_wait:=--wait --rollback-on-failure --timeout ${helm_wait_timeout:-4m}}
    local default_cmd="helm uninstall"
    run-helm uninstall ${helm_atomic_wait}
}

action::helm-get-manifests() {
    local release=${helm_release:=$(basename $target_name)}
    log-info helm "helm-get-manifests from helm release ${release} in namespace $kube_namespace to ${manifest_dir}"
    run-verbose-cmd rm -rf ${manifest_dir}
    run-verbose-cmd mkdir -p ${manifest_dir}
    run-verbose-cmd helm get manifest $release $(helm-cluster-options) \| split-yaml-docs-into-files
}

action::helm-get-diff() { action::helm-diff; } # TODO: deprecated
action::helm-diff() {
    run-actions render
    # do a check status to see if the release exists
    local release=${helm_release:=$(basename $target_name)}
    log-debug helm "checking for helm release ${release} in namespace $kube_namespace"
    ignore_cmd_exit_code=true
    run-verbose-cmd helm status $release $(helm-cluster-options) >/dev/null
    if [[ ${cmd_exit_code:-0} != 0 ]] ; then
        log-info helm "helm release $helm_release does not yet exist in namespace $kube_namespace, skipping helm-diff"
        return 0;
    fi

    local render_dir=$manifest_dir
    local get_dir=${with_dir:-tmp/get}/${target_name}
    log-info helm "helm-diff ${get_dir} with rendered ${render_dir}"
    local manifest_dir=$get_dir
    run-actions helm-get-manifests
    # The sed script is to make missing or added manifests stand out more clearly
    run-verbose-cmd diff -r $get_dir $render_dir | sed 's/^Only in /<> ONLY IN /' || true
}

action::helm-print-value() {
    use-karmah-var json_path
    helm-get-path-value $json_path
}

render-helm() {
    use-paths ${helm_value_files[@]}
    run-helm template \| split-yaml-docs-into-files
}

action::helm-import() {
    log-info helm "helm-import for $target_name"
    # based on https://github.com/jzbruno/helm-import/blob/main/helm-import.sh
    run-helm template \| run-kubectl annotate -f- "meta.helm.sh/release-name=${helm_release}" "meta.helm.sh/release-namespace=${kube_namespace}" --overwrite || true
    run-helm template \| run-kubectl label -f- "app.kubernetes.io/managed-by=Helm" --overwrite || true
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
    run-verbose-cmd yq -i $path=\"$value\"   $val_file
    if ! ${helm_value_already_updated:-false}; then
        change-paths $val_file
        helm_value_already_updated=true
    fi
}

helm-cluster-options() {
    use-karmah-var kube_config
    use-karmah-var kube_context
    use-karmah-var kube_namespace
    local cfg=${kube_config:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+=" --kube-context ${kube_context}"
    opt+=" --namespace $kube_namespace"
    echo $opt
}
