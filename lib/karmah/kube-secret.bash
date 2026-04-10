kube-secret::init-climah-module() {
    module-add-help "actions to work with kubernetes secrets"
    add-karmah-action ksu kube-secret-update   "update or create a kubernetes secret (kubectl apply)"
    add-karmah-action ksg kube-secret-get      "get the value of a kubernetes secret for use in following action"
    add-karmah-action ksp kube-secret-print    "prints the value of a kubernetes secret"
    add-karmah-action ksd kube-secret-diff     "prints the changes to a kubernetes secret"
    add-karmah-action ksm kube-secret-manifest "prints the manifest of the secret to be created"
    local_vars+=" kube_secret_name kube_secret_field secret_value"
}

kube-secret-manifest() {
    cat <<EOF
apiVersion: v1
data:
    ${kube_secret_field}: $(echo -n ${secret_value} | base64)
kind: Secret
metadata:
    name: ${kube_secret_name}
    namespace: ${kube_namespace}
    #annotations:
    #    bao-role-policies: $(bao-role-policies)
type: Opaque
EOF
}

run-action-kube-secret-update() {
    verbose kubectl $(kubectl-options) apply -f ...
    kube-secret-manifest | kubectl $(kubectl-options) apply -f -
}

run-action-kube-secret-get() {
    verbose kubectl $(kubectl-options) get secrets ${kube_secret_name} -o jsonpath="{.data.${kube_secret_field}}"
    local val=$(kubectl $(kubectl-options) get secrets  ${kube_secret_name} -o jsonpath="{.data.${kube_secret_field}}")
    secret_value=$(echo -n $val| base64 -d)
}

run-action-kube-secret-print()    { run-action-kube-secret-get; echo $secret_value; }
run-action-kube-secret-diff()     { kube-secret-manifest | kubectl $(kubectl-options) diff -f -; }
run-action-kube-secret-manifest() { kube-secret-manifest; }
