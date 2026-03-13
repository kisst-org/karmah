kube-init-climah-module() {
    module-add-help "" "actions to work with kubernetes"
    add-karmah-action kd kube-diff    "compare rendered manifests with cluster (kubectl diff)"
    add-karmah-action ka kube-apply   "apply rendered manifests with cluster (kubectl apply)"
    add-karmah-action "" kube-delete  "delete all manifests from cluster (kubectl delete)"
    add-karmah-action kw kube-watch   "watch target resources every 2 seconds"

    help_level=expert
    add-karmah-action ""  kube-get       "get current manifests from cluster to --to <path> (default) deployed/manifests"
    add-karmah-action ""  kube-diff-del  "show resources that will be deleted with kube-delete"
    add-karmah-action ""  kube-tmp-scale "scale resource(s) without changing source or deployment files"
    add-karmah-action ""  kube-restart   "restart resource(s)"
    add-karmah-action k   kubectl        "generic kubectl in the right cluster and namespace of all targets"
    add-karmah-action ks  kube-status    "show status of relevant resources"
    add-karmah-action ke  kube-exec      "execute a command on a pod of a resource"
    add-karmah-action kei kube-exec-it   "execute interactive command on a pod of a resource"
    add-karmah-action kl  kube-log       "show logging of a resource"

    set-pre-actions update,render                       kube-diff
    set-pre-actions update,render,kube-diff,ask         kube-apply
    set-pre-actions update,render,kube-diff-delete,ask  kube-delete
    set-pre-actions render                              kube-diff-del

    options-add R replicas nr  "specify number of replicas"
    options-add r resource res "specify a resource"
    local_vars+=" kube_config kube_context kube_namespace"
    # TODO local_arrays+=" kube_resource_alias kube_default_replicas"
}

parse-option-resource()  { kube_resource_list+=" $2"; argparse_parse_count=2; }
parse-option-replicas()  { kube_replicas="$2";  argparse_parse_count=2; }

kubectl-options() {
    local cfg=${kube_config:-default}
    local opt=""
    if [[ $cfg != default ]]; then
        opt="--kubeconfig $cfg " # extra space at end
    fi
    opt+="--context ${kube_context} -n $kube_namespace"
    echo $opt
}
kubectl-run() {
    verbose-cmd kubectl $(kubectl-options) "${@}"
}

filter-kube-diff-output() { grep -E '^[+-] |^---' | grep -vE '^[+-]  generation: [0-9]*$'; }
filter-kube-diff-quiet() { filter-kube-diff-output | grep -E ^--- | sed -e 's|--- /tmp/LIVE-[0-9]*/||' -e 's/[ \t].*$//' -e 's/^/  changed: /'; }

run-action-kube-diff() {
    info kube-diff ${target_name} to ${output_dir}
    if ${quiet_diff:-false}; then
        #KUBECTL_EXTERNAL_DIFF='diff -qr'
        verbose-pipe filter-kube-diff-quiet kubectl diff $(kubectl-options) -f $output_dir || true
    elif $(log-is-verbose); then
        verbose-cmd kubectl diff $(kubectl-options) -f $output_dir || true
    else
        verbose-pipe filter-kube-diff-output kubectl diff $(kubectl-options) -f $output_dir || true
    fi
}

run-action-kube-diff-delete() {
    info kube-diff-delete all resources ${target_name} from ${output_dir}
    verbose-cmd ls -l $output_dir
}

run-action-kube-apply() {
    info kube-apply $output_dir
    verbose-cmd kubectl apply $(kubectl-options) -f $output_dir
}

run-action-kube-delete() {
    info kube delete $output_dir
    verbose-cmd kubectl delete $(kubectl-options) -f $output_dir
}

run-action-kubectl() {
    info kubectl $output_dir
    verbose-cmd kubectl $(kubectl-options) $action_args
}

# TODO: This is slightly different form render split-into-files
# because it is a yaml list, not separate yaml documents
kubectl-split-into-files() {
    yq  '.items.[]' -s \"$output_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
}

run-action-kube-get-manifests() {
    info kube get manifests  ${target_name} to ${output_dir}
    verbose-cmd rm -rf ${output_dir}
    verbose-cmd mkdir -p ${output_dir}
    verbose-pipe kubectl-split-into-files kubectl $(kubectl-options) get deploy,svc,sts,cm,ingress -o yaml
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
    verbose-cmd kubectl $(kubectl-options) get ${action_args:-pods,deploy,sts,cm}
}
run-action-kube-watch() {
    verbose-cmd watch kubectl $(kubectl-options) get ${action_args:-pods,deploy,sts,cm,svc,ingress,pdb}
}
run-action-kube-exec() {
    verbose-cmd kubectl $(kubectl-options) exec $(kube-calc-full-resource-names) ${action_args:--- sh}
}
run-action-kube-exec-it() {
    verbose-cmd kubectl $(kubectl-options) exec -it $(kube-calc-full-resource-names) ${action_args:--- sh}
}
run-action-kube-log() {
    verbose-cmd kubectl $(kubectl-options) logs $(kube-calc-full-resource-names) ${action_args:-}
}


run-action-kube-restart() {
    local res
    for res in ${kube_resource_list//,/ }; do
        res=${kube_resource_alias[$res]:-$res}
        verbose-cmd kubectl $(kubectl-options) rollout restart $res
    done
}
run-action-kube-tmp-scale() {
    local res
    for res in $(kube-calc-resource-names all); do
        local repl=$(kube-calc-replicas $res)
        res=${kube_resource_alias[$res]:-$res}
        verbose-cmd kubectl $(kubectl-options) scale $res --replicas ${repl}
    done
}

kube-calc-resource-names() {
    local result=${kube_resource_list:-all}
    if [[ $result == all ]]; then
        result=${kube_all_resources}
    fi
    echo ${result//,/ }
}

kube-calc-full-resource-names() {
    local r result="" res=${kube_resource_list:-${1:-}}
    if [[ $res == all ]]; then
        res=${kube_all_resources}
    fi
    for r in ${res//,/ }; do
        result+=" ${kube_resource_alias[$r]:-$r}"
    done
    echo ${result//,/ }
}


kube-calc-replicas() {
    local repl=${kube_replicas:-default}
    if [[  $repl == default ]]; then
        repl=${kube_default_replicas[$1]}
    fi
    echo $repl
}

render-kustomize() {
    local command="kubectl kustomize --enable-helm"
    #used_files+=" $helm_chart_dir/$ch"
    verbose-pipe split-into-files "$command ${karmah_dir}"
}
