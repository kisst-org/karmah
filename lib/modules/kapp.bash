
kapp::init-module() {
    add-module-help "actions to work with kapp"
    help_level=expert
    declare-action "" kapp-plan    "show what resources will be updated"
    declare-action "" kapp-diff    "show what resources will be updated, including detailed diffs"
    declare-action "" kapp-deploy  "deploy the application with kapp"
    declare-action "" kapp-delete  "delete the application with kapp"
}

kapp-options() {
    local cfg=${kube_config:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+=" $yes_arg --kubeconfig-context ${kube_context} -n ${kube_namespace} -a $(basename $target_name) -f ${manifest_dir}"
    echo $opt
}

action::kapp-diff() {
    run-pre-actions render
    run-verbose-cmd kapp deploy $(kapp-options) --diff-run --diff-changes
}

action::kapp-plan() {
    run-pre-actions render
    run-verbose-cmd kapp deploy $(kapp-options) --diff-run
}

action::kapp-deploy() {
    run-pre-actions render
    if ! kubectl $(kubectl_options) get ns $kube_namespace >/dev/null 2>&1; then
        run-verbose-cmd kubectl $(kubectl_options) create ns $kube_namespace
    fi
    run-verbose-cmd kapp deploy $(kapp-options)
}

action::kapp-delete() {
    run-verbose-cmd kapp delete $(kapp-options)
}
