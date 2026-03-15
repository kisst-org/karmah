
kapp::init-climah-module() {
    module-add-help "actions to work with kapp"
    set-action-pre-flow update,render kapp-plan kapp-diff kapp-deploy kapp-delete
    help_level=expert
    add-karmah-action "" kapp-plan    "show what resources will be updated"
    add-karmah-action "" kapp-diff    "show what resources will be updated, including detailed diffs"
    add-karmah-action "" kapp-deploy  "deploy the application with kapp"
    add-karmah-action "" kapp-delete  "delete the application with kapp"
}

kapp-options() {
    local cfg=${kube_config:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+=" $yes_arg --kubeconfig-context ${kube_context} -n ${kube_namespace} -a $(basename $target_name) -f ${output_dir}"
    echo $opt
}

run-action-kapp-diff() {
    verbose-cmd kapp deploy $(kapp-options) --diff-run --diff-changes
}

run-action-kapp-plan() {
    verbose-cmd kapp deploy $(kapp-options) --diff-run
}

run-action-kapp-deploy() {
    if ! kubectl $(kubectl_options) get ns $kube_namespace >/dev/null 2>&1; then
        verbose-cmd kubectl $(kubectl_options) create ns $kube_namespace
    fi
    verbose-cmd kapp deploy $(kapp-options)
}

run-action-kapp-delete() {
    verbose-cmd kapp delete $(kapp-options)
}
