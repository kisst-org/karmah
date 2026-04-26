
kapp::init-module() {
    add-module-help "actions to work with kapp"
    help_level=expert
    add-render-action "" kapp-plan    "show what resources will be updated"
    add-render-action "" kapp-diff    "show what resources will be updated, including detailed diffs"
    add-render-action "" kapp-deploy  "deploy the application with kapp"
    add-render-action "" kapp-delete  "delete the application with kapp"
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
    run-cmd-from-action verbose kapp deploy $(kapp-options) --diff-run --diff-changes
}

run-action-kapp-plan() {
    run-cmd-from-action verbose kapp deploy $(kapp-options) --diff-run
}

run-action-kapp-deploy() {
    if ! kubectl $(kubectl_options) get ns $kube_namespace >/dev/null 2>&1; then
        run-cmd-from-action verbose kubectl $(kubectl_options) create ns $kube_namespace
    fi
    run-cmd-from-action verbose kapp deploy $(kapp-options)
}

run-action-kapp-delete() {
    run-cmd-from-action verbose kapp delete $(kapp-options)
}
