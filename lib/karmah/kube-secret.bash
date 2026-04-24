kube-secret::init-climah-module() {
    add-module-help "actions to work with kubernetes secrets"
    add-karmah-action ksu kube-secret-update   "update or create a kubernetes secret (kubectl apply)"
    add-karmah-action ksg kube-secret-get      "get the value of a kubernetes secret for use in following action"
    add-karmah-action ksp kube-secret-print    "prints the value of a kubernetes secret"
    add-karmah-action ksd kube-secret-diff     "prints the changes to a kubernetes secret"
    add-karmah-action ksm kube-secret-manifest "prints the manifest of the secret to be created"
    add-karmah-action kspy kube-secret-print-yaml "print the data stored in a secret as yaml"
    add-karmah-action kssf kube-secret-save-files "save the data stored in a secret as file(s)"
    local_vars+=" kube_secret_name kube_secret_field secret_value"
    add-karmah-var secret_name "the name of the secret"
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

run-action-kube-secret-save-files() {
    use-karmah-var secret_name
    info "getting file(s) from secret $secret_name"
    local data=$(kubectl $(kubectl-options) get secret $secret_name -o yaml | yq .data)
    if [[ $data == null ]]; then
        error "no secret found with name $secret_name"
        exit 1
    fi
    local line; for line in ${data//: /:}; do
        local name=${line/:*/}
        local content=${line//*:/}
        info saving $name
        echo  $content | base64 -d >$name
    done
}

run-action-kube-secret-print-yaml() {
    use-karmah-var kube-secret:secret_name
    info "getting file(s) from secret $secret_name"
    local data=$(kubectl $(kubectl-options) get secret $secret_name -o yaml | yq .data)
    if [[ $data == null ]]; then
        error "no secret found with name $secret_name"
        exit 1
    fi
    local line; for line in ${data//: /:}; do
        local name=${line/:*/}
        local content=${line//*:/}
        echo $name: $(echo $content | base64 -d)
    done
}
