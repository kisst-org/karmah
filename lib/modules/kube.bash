kube::init-module() {
    add-module-help "helper actions to work with kubernetes"
    add-func-option R replicas nr  "specify number of replicas"
    add-func-option r resource res "specify a resource"

    add-karmah-action kw kube-watch   "watch target resources every 2 seconds"
    add-karmah-action ""  kube-get       "get current manifests from cluster to --to <path> (default) deployed/manifests"
    add-karmah-action ""  kube-tmp-scale "scale resource(s) without changing source or deployment files"
    add-karmah-action ""  kube-restart   "restart resource(s)"
    add-karmah-action ""  kube-env       "show the environment vars of a pod (run env in a shell)"
    add-karmah-action kl  kube-log       "show logging of a resource"
    help_level=expert
    add-karmah-action k   kubectl        "generic kubectl in the right cluster and namespace of all targets"
    #add-karmah-action ks  kube-status    "show status of relevant resources"
    add-karmah-action ke  kube-exec      "execute a command on a pod of a resource"
    add-karmah-action kei kube-exec-it   "execute interactive command on a pod of a resource"
    add-karmah-action kst kube-stern     "use stern to show logging of multiple pods"

    local_vars+=" kube_config kube_context kube_namespace"
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
run-kubectl() {
    run-cmd-from-action verbose kubectl $(kubectl-options) "${@}"
}

action::kubectl() {
    log-info kube "kubectl $output_dir"
    run-cmd-from-action verbose kubectl $(kubectl-options) $action_args
}

action::kube-get-manifests() {
    log-info kube "kube get manifests  ${target_name} to ${output_dir}"
    run-cmd-from-action verbose rm -rf ${output_dir}
    run-cmd-from-action verbose mkdir -p ${output_dir}
    run-verbose-cmd kubectl $(kubectl-options) get deploy,svc,sts,cm,ingress -o yaml \| split-yaml-items-into-files
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

action::kube-get() {
    run-cmd-from-action verbose kubectl $(kubectl-options) get ${action_args:-pods,deploy,sts,cm}
}
action::kube-watch() {
    run-cmd-from-action verbose watch kubectl $(kubectl-options) get $(kube-calc-resource kube-watch pods,deploy,sts,cm,svc,ingress,pdb) ${action_args:-}
}
action::kube-exec() {
    run-cmd-from-action verbose kubectl $(kubectl-options) exec $(kube-calc-resource kube-exec) ${action_args:--- sh}
}
action::kube-env() {
    run-cmd-from-action verbose kubectl $(kubectl-options) exec $(kube-calc-resource kube-exec) -- sh -c env
}

action::kube-exec-it() {
    run-cmd-from-action verbose kubectl $(kubectl-options) exec -it $(kube-calc-resource kube-exec-it) ${action_args:--- sh}
}
action::kube-log() {
    run-cmd-from-action verbose kubectl $(kubectl-options) logs $(kube-calc-resource kube-log) ${action_args:-}
}
action::kube-stern() {
    run-cmd-from-action verbose stern $(kubectl-options)  $(kube-calc-resource kube-stern) ${action_args:-}
}


action::kube-restart() {
    local res
    for res in ${kube_resource_list//,/ }; do
        res=${kube_resource_alias[$res]:-$res}
        run-cmd-from-action verbose kubectl $(kubectl-options) rollout restart $res
    done
}
action::kube-tmp-scale() {
    local res
    for res in $(kube-calc-resource-names all); do
        local repl=$(kube-calc-replicas $res)
        res=${kube_resource_alias[$res]:-$res}
        run-cmd-from-action verbose kubectl $(kubectl-options) scale $res --replicas ${repl}
    done
}
kube-calc-replicas() {
    local repl=${kube_replicas:-default}
    if [[  $repl == default ]]; then
        ${karmah_type}::kube-default-replicas $1
    else
        echo $repl
    fi
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


render-kustomize() {
    local command="kubectl kustomize --enable-helm"
    #used_files+=" $helm_chart_dir/$ch"
    run-verbose-cmd kubectl "$command ${karmah_dir}" \| split-yaml-docs-into-files
}

kube-calc-resource() {
    local action=$1 defaults="${2:-}"
    if  [[ $(type -t ${karmah_type}::$action-resource) == function ]]; then
        ${karmah_type}::$action-resource
    elif [[ $(type -t ${karmah_type}::calc-kube-resource) == function ]]; then
        ${karmah_type}::calc-kube-resource
    else
        echo $defaults
    fi
}
empty::calc-kube-resource() { echo ${kube_resource:-deployment}; }
