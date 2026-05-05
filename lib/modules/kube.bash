kube::init-module() {
    add-module-help "helper actions to work with kubernetes"
    add-karmah-var R replicas nr  "specify number of replicas"
    add-karmah-var r resource res "specify a resource"

    add-karmah-action kw   kube-watch        "watch target resources every 2 seconds"
    add-karmah-action kl   kube-log          "show logging of a resource"
    add-karmah-action kg   kube-get          "get current manifests from cluster to --to <path> (default) deployed/manifests"
    add-karmah-action ""   kube-scale        "scale resource(s) without changing source or deployment files"
    add-karmah-action ""   kube-restart      "rollout restart resource(s)"
    add-karmah-action kenv kube-env          "show the environment vars of a pod (run env in a shell)"
    add-karmah-action kup  kube-uptime       "run the uptime commando on a pod"
    help_level=expert
    add-karmah-action k   kubectl            "generic kubectl in the right cluster and namespace of all targets"
    #add-karmah-action ks  kube-status    "show status of relevant resources"
    add-karmah-action ke  kube-exec          "execute a command on a pod of a resource"
    add-karmah-action kei kube-exec-it       "execute interactive command on a pod of a resource"
    add-karmah-action kst kube-stern         "use stern to show logging of multiple pods"
    add-karmah-action kgm kube-get-manifests "get current manifests from cluster to --to <path> (default) deployed/manifests"

    add-karmah-var "" kube_config  "file" "The kube config file to be used (default means none)"
    add-karmah-var "" kube_context "ctx"  "The kube context"
    add-karmah-var "" kube_namespace "ns" "The kube namespace"
    #local_vars+=" kube_config kube_context kube_namespace"
}

kubectl-options() {
    use-karmah-var kube_context
    use-karmah-var kube_config
    use-karmah-var kube_namespace
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
    run-cmd-from-action verbose kubectl $(kubectl-options) get $(kube-calc-resource kube-get) ${action_args:-}
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
action::kube-uptime() {
    run-cmd-from-action verbose kubectl $(kubectl-options) exec $(kube-calc-resource kube-exec) -- uptime
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
action::kube-scale() {
    local res
    for res in $(kube-calc-resource-names all); do
        local repl=$(kube-calc-replicas $res)
        res=${kube_resource_alias[$res]:-$res}
        echo run-kubectl scale $res --replicas ${repl}
    done
}
kube-calc-replicas() {
    use-karmah-var replicas
    if [[  $replicas == default ]]; then
        ${karmah_type}::kube-default-replicas $1
    else
        echo $replicas
    fi
}

kube-calc-resource-names() {
    local result=${kube_resource_list:-all}
    if [[ $result == all ]]; then
        result=${kube_all_resources}
    fi
    echo ${result//,/ }
}

_echo_if_func_exsists() {
    if  $(function-exists $1); then
        echo $1
        return 0
    fi
    return 1
}

kube-calc-resource-func() {
    local kube_action=$1
    local typ=$1; for typ in $(karmah-parents); do
        if _echo_if_func_exsists $typ::calc-${kube_action}-resource; then return; fi
        if _echo_if_func_exsists $typ::calc-kube-resource;    then return; fi
    done
}
kube-calc-resource() {
    local kube_action=$1 defaults="${2:-}"
    local func=$(kube-calc-resource-func $kube_action)
    use-karmah-var resource default
    local result=""
    local res; for res in ${resource//,/ }; do
        result+=" $($func $res)"
    done
    result=${result# } # trim leading space
    echo ${result// /,}
}

base::calc-kube-watch-resource() { ifed-combi::calc-kube-get-resource; }
base::calc-kube-resource() { echo pod,deployment,ingress; }
