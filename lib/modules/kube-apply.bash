kube-apply::init-module() {
    add-module-help "actions to work with kubernetes apply"
    add-render-action kd kube-diff     "compare rendered manifests with cluster (kubectl diff)"
    add-render-action "" kube-apply    "apply rendered manifests with cluster (kubectl apply)"
    help_level=expert
    add-render-action "" kube-delete   "delete all manifests from cluster (kubectl delete)"
    add-karmah-action "" kube-diff-del "show resources that will be deleted with kube-delete"
    set-action-pre-flow load-karmah,update,render,kube-diff,ask         kube-apply
    set-action-pre-flow load-karmah,update,render,kube-diff-delete,ask  kube-delete
}

filter-kube-diff-output() { grep -E '^[+-] |^---' | grep -vE '^[+-]  generation: [0-9]*$'; }
filter-kube-diff-quiet() { filter-kube-diff-output | grep -E ^--- | sed -e 's|--- /tmp/LIVE-[0-9]*/||' -e 's/[ \t].*$//' -e 's/^/  changed: /'; }

run-action-kube-diff() {
    log-info kube "kube-diff ${target_name} to ${output_dir}"
    if ${quiet_diff:-false}; then
        #KUBECTL_EXTERNAL_DIFF='diff -qr'
        verbose-pipe filter-kube-diff-quiet kubectl diff $(kubectl-options) -f $output_dir || true
    elif $(log-is-verbose); then
        run-cmd-from-action verbose kubectl diff $(kubectl-options) -f $output_dir || true
    else
        verbose-pipe filter-kube-diff-output kubectl diff $(kubectl-options) -f $output_dir || true
    fi
}

run-action-kube-diff-delete() {
    log-info kube "kube-diff-delete all resources ${target_name} from ${output_dir}"
    run-cmd-from-action verbose ls -l $output_dir
}

run-action-kube-apply() {
    log-info kube "kube-apply $output_dir"
    run-cmd-from-action verbose kubectl apply $(kubectl-options) -f $output_dir
}

run-action-kube-delete() {
    log-info kube "kube delete $output_dir"
    run-cmd-from-action verbose kubectl delete $(kubectl-options) -f $output_dir
}
