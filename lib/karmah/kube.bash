init_climah_module_kube() {
    use_module render
    declare -Ag kube_config_map
    declare -Ag kube_context_map
    #declare -g kube_resource_list
    add_action kube-get "get current manifests from cluster to --to <path> (default) deployed/manifests"
    add_action kube-apply "apply rendered manifests with cluster (kubectl apply)"
    add_action kube-delete "delete all manifests from cluster (kubectl delete)"
    add_action kube-diff "compare rendered manifests with cluster (kubectl diff)"
    add_action kube-tmp-scale "scale resource(s) without changing source or deployment files"
    add_action kube-restart "restart resource(s)"
    add_action kubectl --collect "generic kubectl in the right cluster and namespace of all targets"
    add_option R replicas nr  "specify number of replicas"
    global_vars+=" kube_cluster namespace"
    global_arrays+=" kube_resource_alias kube_default_replicas"
}

parse_option_resource()  { kube_resource_list+=" $2"; parse_result=2; }
parse_option_replicas()  { kube_replicas="$2";  parse_result=2; }


kubectl_options() {
    local cl=${kube_cluster}
    local cfg=${kube_config_map[$cl]:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kube_config_map $cfg " # extra space at end
    fi
    opt+="--context ${kube_context_map[$cl]} -n $namespace"
    echo $opt
}

filter-kube-diff-output() { grep -E '^[+-] |^---'; }
run_action_kube-diff() {
    render_manifests
    info kube-diff ${target} to ${output_dir}
    if $(log_is_verbose); then
        verbose_cmd kubectl diff $(kubectl_options) -f $output_dir || true
    else
        verbose_pipe filter-kube-diff-output kubectl diff $(kubectl_options) -f $output_dir || true
    fi
}

run_action_kube-apply() {
    render_manifests
    run_action_kube-diff
    info kube apply $output_dir
    verbose_cmd kubectl apply $(kubectl_options) -f $output_dir
}

run_action_kube-delete() {
    render_manifests # render manifests to be deleted
    run_action_kube-diff
    info kube delete $output_dir
    verbose_cmd kubectl delete $(kubectl_options) -f $output_dir
}


run_action_kubectl() {
    info kubectl $output_dir
    verbose_cmd kubectl $(kubectl_options) $extra_args
}


split_kubectl_output_into_files() {
    yq  '.items.[]' -s \"$output_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
}

run_action_kube-get-manifests() {
    info kube get manifests  ${target} to ${output_dir}
    verbose_cmd rm -rf ${output_dir}
    verbose_cmd mkdir -p ${output_dir}
    verbose_pipe split_kubectl_output_into_files kubectl ${kubectl_options[$kube_cluster]} -n "${namespace}" get deploy,svc,sts,cm,ingress -o yaml
    ignore_files=configmap_kube-root-ca.crt.yaml
    ignore_files+=" deployment_ingress-nginx-controller.yaml"
    ignore_files+=" service_ingress-nginx-controller-admission.yaml"
    ignore_files+=" service_ingress-nginx-controller.yaml"
    for f in ${ignore_files}; do
        rm -f "${output_dir}/$f"
    done
    for f in "${output_dir}"/*.yaml; do
         yq -i 'del(.metadata.annotations.["kubectl.kubernetes.io/last-applied-configuration"])' "${f}"
         yq -i 'del(.metadata.uid)' "${f}"
         yq -i 'del(.metadata.resourceVersion)' "${f}"
         yq -i 'del(.metadata.creationTimestamp)' "${f}"
    done
}

run_action_kube-get() {
    verbose_cmd kubectl $(kubectl_options) -n $namespace get ${extra_args:-pods,deploy,sts,cm}
}
run_action_kube-watch() {
    verbose_cmd watch kubectl $(kubectl_options) -n $namespace get ${extra_args:-pods,deploy,sts,cm}
}
run_action_kube-restart() {
    local res
    for res in ${kube_resource_list//,/ }; do
        res=${kube_resource_alias[$res]:-$res}
        verbose_cmd kubectl $(kubectl_options) -n $namespace rollout restart $res
    done
}
run_action_kube-tmp-scale() {
    local res
    for res in $(calc_resource_names); do
        verbose_cmd kubectl $(kubectl_options) -n $namespace scale $res --replicas $(calc_kube_replicas $res)
    done
}

calc_resource_names() {
    local result=${kube_resource_list:-all}
    if [[ $result == all ]]; then
        result=${all_resources}
    fi
    echo ${result//,/ }
}

calc_kube_replicas() {
    local repl=${kube_replicas:-default}
    if [[  $repl == default ]]; then
        repl=${kube_default_replicas[$1]}
    fi
    echo $repl
}
