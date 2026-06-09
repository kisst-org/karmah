kube::init-module() {
    add-module-help "helper actions to work with kubernetes"
    add-karmah-var R replicas nr  "specify number of replicas"
    add-karmah-var r resource res "specify a resource"


    local action_params="..."
    declare-action kw   kube-watch        "watch target resources every 2 seconds"
    declare-action kl   kube-log          "show logging of a pod"
    declare-action klf  kube-log-follow   "follow logging of a pod"
    declare-action kg   kube-get          "get a resource"
    declare-action kbak kube-backup       "backup specified resources"
    declare-action kdsc kube-describe     "describe a resource"
    declare-action ""   kube-scale        "scale resource(s) without changing source or deployment files"
    declare-action ""   kube-restart      "rollout restart resource(s)"
    declare-action kenv kube-env          "show the environment vars of a pod (run env in a shell)"
    declare-action kev  kube-events       "show the events of a resource"
    declare-action kup  kube-uptime       "run the uptime commando on a pod"
    declare-action kes  kube-es-sync      "sync external secrets"
    declare-action kpip kube-pod-ip       "show pods with IP"
    declare-action kpn  kube-pod-node     "show pods with node"
    help_level=expert
    declare-action k   kubectl            "generic kubectl in the right cluster and namespace of all targets"
    #declare-action ks  kube-status    "show status of relevant resources"
    declare-action ke  kube-exec          "execute a command on a pod of a resource"
    declare-action kei kube-exec-it       "execute interactive command on a pod of a resource"
    declare-action kst kube-stern         "use stern to show logging of multiple pods"
    declare-action kgm kube-get-manifests "get current manifests from cluster to --to <path> (default) deployed/manifests"

    add-karmah-var "" kube_config  "file" "The kube config file to be used (default means none)"
    add-karmah-var "" kube_context "ctx"  "The kube context"
    add-karmah-var "" kube_namespace "ns" "The kube namespace"
    #local_vars+=" kube_config kube_context kube_namespace"
    add-flag-option A all-namespaces  "search all namespaces"
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
    if $(get-option-value all-namespaces false); then
        run-verbose-cmd kubectl $(kubectl-options) "${@}" --all-namespaces
    else
        run-verbose-cmd kubectl $(kubectl-options) "${@}"
    fi
}

action::kubectl() {
    log-info kube "kubectl $manifest_dir"
    # TODO: would be nice if we could use calced resource somewhere
    run-kubectl "$@"
}

action::kube-get-manifests() {
    log-info kube "kube get manifests  ${target_name} to ${manifest_dir}"
    run-verbose-cmd rm -rf ${manifest_dir}
    run-verbose-cmd mkdir -p ${manifest_dir}
    run-verbose-cmd kubectl $(kubectl-options) get deploy,svc,sts,cm,ingress -o yaml \| split-yaml-items-into-files
    ignore_files=configmap_kube-root-ca.crt.yaml
    ignore_files+=" deployment_ingress-nginx-controller.yaml"
    ignore_files+=" service_ingress-nginx-controller-admission.yaml"
    ignore_files+=" service_ingress-nginx-controller.yaml"
    for f in ${ignore_files}; do
        rm -f "${manifest_dir}/$f"
    done
    for f in "${manifest_dir}"/*.yaml; do
         yq -i 'del(.metadata.annotations.["kubectl.kubernetes.io/last-applied-configuration"])' "${f}"
         yq -i 'del(.metadata.uid)' "${f}"
         yq -i 'del(.metadata.resourceVersion)' "${f}"
         yq -i 'del(.metadata.creationTimestamp)' "${f}"
    done
}

action::kube-backup() {
    use-karmah-var resource
    local manifest_dir="$(get-option-value to "tmp/backup-$(date -Idate)/$kube_context")" # TODO: better option than context
    local res; for res in ${resource//,/ }; do
        log-info kube.backup "backing up $res to $manifest_dir"
        run-kubectl get $res "${@}" -o yaml| split-yaml-items-into-files
    done
    for f in "${manifest_dir}"/*.yaml; do
        log-info kube.backup "cleaning up $f"
        yq -i 'del(.metadata.annotations.["kubectl.kubernetes.io/last-applied-configuration"])' "${f}"
        yq -i 'del(.metadata.uid)' "${f}"
        yq -i 'del(.metadata.resourceVersion)' "${f}"
        yq -i 'del(.metadata.creationTimestamp)' "${f}"
        yq -i 'del(.status)' "${f}"
    done
}

action::kube-get() {
    run-kubectl get $(kube-calc-resource kube-get) "${@}"
}
action::kube-describe() {
    run-kubectl describe $(kube-calc-resource kube-describe) "${@}"
}
action::kube-events() {
    run-kubectl events $(kube-calc-resource kube-events) "${@}"
}

action::kube-watch() {
run-verbose-cmd watch kubectl $(kubectl-options) get $(kube-calc-resource kube-watch pods,deploy,sts,cm,svc,ingress,pdb) "${@}"
}
action::kube-exec() {
    run-kubectl exec $(kube-calc-resource kube-exec) "${@:--- sh}"
}
action::kube-env() {
    run-kubectl exec $(kube-calc-resource kube-exec) -- sh -c env
}
action::kube-uptime() {
    run-kubectl exec $(kube-calc-resource kube-exec) -- uptime
}
action::kube-restart() {
    run-kubectl rollout restart $(kube-calc-resource kube-restart)
}
action::kube-exec-it() {
    run-kubectl exec -it $(kube-calc-resource kube-exec-it) "${@:--- sh}"
}
action::kube-log() {
    run-kubectl logs $(kube-calc-resource kube-log) "${@}"
}
action::kube-log-follow() {
    run-kubectl logs $(kube-calc-resource kube-log) "${@}" --follow
}
action::kube-es-sync() {
    # see https://external-secrets.io/latest/introduction/faq/
    run-kubectl annotate $(kube-calc-resource kube-es-sync) force-sync=$(date +%s) --overwrite  "${@}"
}
action::kube-pod-ip() {
    run-kubectl get pods -o custom-columns='NAME:metadata.name,IP:status.podIP'
}
action::kube-pod-node() {
    run-kubectl get pods -o custom-columns='NAME:metadata.name,IP:spec.nodeName'
}


action::kube-stern() {
    run-verbose-cmd stern $(kubectl-options)  $(kube-calc-resource kube-stern) "${@}"
}

action::kube-scale() {
    run-kubectl scale $(kube-calc-resource kube-scale) --replicas $(kube-calc-replicas)
}

kube-calc-replicas() {
    use-karmah-var replicas
    if [[  $replicas == default ]]; then
        ${karmah_type}::kube-default-replicas
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


kube-calc-resource() {
    local kube_action=$1 defaults="${2:-}"
    use-karmah-var resource default
    local result=""
    local res; for res in ${resource//,/ }; do
        find-karmah-method-output calc-resource-${kube_action} $res
    done
    result=$(echo $result) # trim spaces
    echo ${result// /,}
}

find-karmah-method-output() {
    local method=$1; shift
    local cls; for cls in $(karmah-classes); do
        if $(function-exists $cls::$method); then
            local val="$($cls::$method "$@")"
            if [[ ! -z $val ]]; then
                echo "$val"
                return
            fi
        fi
    done
}

get-latest-pod-name() { run-kubectl get pods --sort-by .status.startTime -o name "$@"  | tail -1; }

base::calc-resource-kube-log-follow() { find-karmah-method-output calc-resource-kube-log $1; }
base::calc-resource-kube-exec-it()    { find-karmah-method-output calc-resource-kube-exec $1; }
base::calc-resource-kube-watch()      { find-karmah-method-output calc-resource-kube-get $1; }
base::calc-resource-kube-describe()   { find-karmah-method-output calc-resource-kube $1; }
base::calc-resource-kube-events()     { find-karmah-method-output calc-resource-kube $1; }
base::calc-resource-kube-log()        { find-karmah-method-output calc-resource-kube $1; }
base::calc-resource-kube-exec()       { find-karmah-method-output calc-resource-kube $1; }
base::calc-resource-kube-get()        { find-karmah-method-output calc-resource-kube $1; }
base::calc-resource-kube-restart()    { find-karmah-method-output calc-resource-kube $1; }
base::calc-resource-kube() { echo pod,deployment,ingress; }
