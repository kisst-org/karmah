init_climah_module_kube() {
    declare -Ag kube_config_map
    declare -Ag kube_context_map
    #declare -g kube_resource_list

    add-action kd kube-diff    "compare rendered manifests with cluster (kubectl diff)"
    add-action ka kube-apply   "apply rendered manifests with cluster (kubectl apply)"
    add-action "" kube-delete  "delete all manifests from cluster (kubectl delete)"
    add-action kw kube-watch   "watch target resources every 2 seconds"

    help_level=expert
    add-action "" kube-get        "get current manifests from cluster to --to <path> (default) deployed/manifests"
    add-action "" kube-diff-del   "show resources that will be deleted with kube-delete"
    add-action "" kube-tmp-scale  "scale resource(s) without changing source or deployment files"
    add-action "" kube-restart    "restart resource(s)"
    add-action k  kubectl         "generic kubectl in the right cluster and namespace of all targets"

    set-pre-actions update,render                       kube-diff
    set-pre-actions update,render,kube-diff,ask         kube-apply
    set-pre-actions update,render,kube-diff-delete,ask  kube-delete
    set-pre-actions render                              kube-diff-del

    add-option R replicas nr  "specify number of replicas"
    local_vars+=" kube_cluster namespace"
    local_arrays+=" kube_resource_alias kube_default_replicas"
}

parse-option-resource()  { kube_resource_list+=" $2"; parse_result=2; }
parse-option-replicas()  { kube_replicas="$2";  parse_result=2; }


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

filter-kube-diff-output() { grep -E '^[+-] |^---' | grep -vE '^[+-]  generation: [0-9]*$'; }
filter-kube-diff-quiet() { filter-kube-diff-output | grep -E ^--- | sed -e 's|--- /tmp/LIVE-[0-9]*/||' -e 's/[ \t].*$//' -e 's/^/  changed: /'; }

run-action-kube-diff() {
    info kube-diff ${target} to ${output_dir}
    if ${quiet_diff:-false}; then
        #KUBECTL_EXTERNAL_DIFF='diff -qr'
        verbose_pipe filter-kube-diff-quiet kubectl diff $(kubectl_options) -f $output_dir || true
    elif $(log_is_verbose); then
        verbose_cmd kubectl diff $(kubectl_options) -f $output_dir || true
    else
        verbose_pipe filter-kube-diff-output kubectl diff $(kubectl_options) -f $output_dir || true
    fi
}

run-action-kube-diff-delete() {
    info kube-diff-delete all resources ${target} from ${output_dir}
    verbose_cmd ls -l $output_dir
}

run-action-kube-apply() {
    info kube-apply $output_dir
    verbose_cmd kubectl apply $(kubectl_options) -f $output_dir
}

run-action-kube-delete() {
    info kube delete $output_dir
    verbose_cmd kubectl delete $(kubectl_options) -f $output_dir
}


run-action-kubectl() {
    info kubectl $output_dir
    verbose_cmd kubectl $(kubectl_options) $extra_args
}


split_kubectl_output_into_files() {
    yq  '.items.[]' -s \"$output_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
}

run-action-kube-get-manifests() {
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

run-action-kube-get() {
    verbose_cmd kubectl $(kubectl_options) -n $namespace get ${extra_args:-pods,deploy,sts,cm}
}
run-action-kube-watch() {
    verbose_cmd watch kubectl $(kubectl_options) -n $namespace get ${extra_args:-pods,deploy,sts,cm}
}
run-action-kube-restart() {
    local res
    for res in ${kube_resource_list//,/ }; do
        res=${kube_resource_alias[$res]:-$res}
        verbose_cmd kubectl $(kubectl_options) -n $namespace rollout restart $res
    done
}
run-action-kube-tmp-scale() {
    local res
    for res in $(calc_resource_names); do
        local repl=$(calc_kube_replicas $res)
        res=${kube_resource_alias[$res]:-$res}
        verbose_cmd kubectl $(kubectl_options) -n $namespace scale $res --replicas ${repl}
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

render_kustomize() {
    local command="kubectl kustomize --enable-helm"
    #used_files+=" $helm_chart_dir/$ch"
    verbose_pipe split_into_files "$command ${karmah_dir}"
}
