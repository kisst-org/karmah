
init_climah_module_kapp() {
    help_level=expert
    add-action "" kapp-plan    update,render   "show what resources will be updated"
    add-action "" kapp-diff    update,render   "show what resources will be updated, including detailed diffs"
    add-action "" kapp-deploy  update,render   "deploy the application with kapp"
    add-action "" kapp-delete  update,render   "delete the application with kapp"
}

kapp_options() {
    local cl=${kube_cluster}
    local cfg=${kube_config_map[$cl]:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kube_config_map $cfg " # extra space at end
    fi
    opt+=" $yes_arg --kube_config_map-context ${kube_context_map[$cl]} -n ${namespace} -a $(basename $target) -f ${output_dir}"
    echo $opt
}

run-action-kapp-diff() {
    verbose_cmd kapp deploy $(kapp_options) --diff-run --diff-changes
}

run-action-kapp-plan() {
    verbose_cmd kapp deploy $(kapp_options) --diff-run
}

run-action-kapp-deploy() {
    if ! kubectl $(kubectl_options) get ns $namespace >/dev/null 2>&1; then
        verbose_cmd kubectl $(kubectl_options) create ns $namespace
    fi
    verbose_cmd kapp deploy $(kapp_options)
}

run-action-kapp-delete() {
    verbose_cmd kapp delete $(kapp_options)
}
