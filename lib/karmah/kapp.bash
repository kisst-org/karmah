
init_climah_module_kapp() {
    add_action kapp-plan "show what resources will be updated"
    add_action kapp-diff "show what resources will be updated, including detailed diffs"
    add_action kapp-deploy "deploy the application with kapp"
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

run_action_kapp-diff() {
    render_manifests
    verbose_cmd kapp deploy $(kapp_options) --diff-run --diff-changes
}

run_action_kapp-plan() {
    render_manifests
    verbose_cmd kapp deploy $(kapp_options) --diff-run
}

run_action_kapp-deploy() {
    run_action_render
    if ! kubectl $(kubectl_options) get ns $namespace >/dev/null 2>&1; then
        verbose_cmd kubectl $(kubectl_options) create ns $namespace
    fi
    verbose_cmd kapp deploy $(kapp_options)
}

run_action_kapp-delete() {
    run_action_render # render manifests to be deleted
    verbose_cmd kapp delete $(kapp_options)
}
