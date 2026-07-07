kube-apply::init-module() {
    add-module-summary "actions to work with kubernetes apply"
    declare-action kd kube-diff     "compare rendered manifests with cluster (kubectl diff)"
    declare-action "" kube-apply    "apply rendered manifests with cluster (kubectl apply)"
    help_level=expert
    declare-action "" kube-delete   "delete all manifests from cluster (kubectl delete)"
    #declare-action "" kube-diff-del "show resources that will be deleted with kube-delete"
}

filter-kube-diff-output() { grep -E '^[+-] |^---' | grep -vE '^[+-]  generation: [0-9]*$'; }
filter-kube-diff-quiet() { filter-kube-diff-output | grep -E ^--- | sed -e 's|--- /tmp/LIVE-[0-9]*/||' -e 's/[ \t].*$//' -e 's/^/  changed: /'; }

action::kube-diff() {
    run-pre-actions render
    local quiet_diff=$(get-option-value quiet-diff false)
    log-info kube "kube-diff ${target_name} to ${manifest_dir}"
    if ${quiet_diff}; then
        #KUBECTL_EXTERNAL_DIFF='diff -qr'
        run-verbose-cmd kubectl diff $(kubectl-options) -f $manifest_dir \| filter-kube-diff-quiet #|| true
    elif $(log-shows-verbose); then
        run-verbose-cmd kubectl diff $(kubectl-options) -f $manifest_dir || true
    else
        run-verbose-cmd kubectl diff $(kubectl-options) -f $manifest_dir \| filter-kube-diff-output # TODO true
    fi
}

action::kube-diff-delete() {
    run-pre-actions render
    log-info kube "kube-diff-delete all resources ${target_name} from ${manifest_dir}"
    run-verbose-cmd ls -l $manifest_dir
}

action::kube-apply() {
    run-pre-actions render,kube-diff,ask
    log-info kube "kube-apply $manifest_dir"
    run-verbose-cmd kubectl apply $(kubectl-options) -f $manifest_dir
}

action::kube-delete() {
    run-pre-actions render,kube-diff-delete,ask
    log-info kube "kube delete $manifest_dir"
    run-verbose-cmd kubectl delete $(kubectl-options) -f $manifest_dir
}
