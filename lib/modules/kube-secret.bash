kube-secret::init-module() {
    add-module-help "actions to work with kubernetes secrets"
    add-karmah-action ksu  kube-secret-update      "update or create a kubernetes secret (kubectl apply)"
    add-karmah-action ksg  kube-secret-get         "get the value of a kubernetes secret for use in following action"
    add-karmah-action kspf kube-secret-print-field "prints the value of a kubernetes secret"
    add-karmah-action ksd  kube-secret-diff        "prints the changes to a kubernetes secret"
    add-karmah-action ksm  kube-secret-manifest    "prints the manifest of the secret to be created"
    add-karmah-action kspf kube-secret-print-field "prints the value of a kubernetes secret"
    add-karmah-action kspy kube-secret-print-yaml  "print the data stored in a secret as yaml"
    add-karmah-action kssf kube-secret-save-files  "save the data stored in a secret as file(s)"
    add-karmah-var secret_name  "the name of a kubernetes secret to be used"
    add-karmah-var secret_field "the name of the field in a kubernetes secret to be used"
    add-karmah-var secret_value "a secret value which is generated, read, stored or printed"
}

kube-secret-manifest() {
    use-karmah-var secret_name
    use-karmah-var secret_value
    use-karmah-var secret_field
    cat <<EOF
apiVersion: v1
data:
    ${secret_field}: $(echo -n ${secret_value} | base64)
kind: Secret
metadata:
    name: ${secret_name}
    namespace: ${kube_namespace}
    #annotations:
    #    bao-role-policies: $(bao-role-policies)
type: Opaque
EOF
}

run-action-kube-secret-update() {
    log-verbose kube-secret "kubectl $(kubectl-options) apply -f ..."
    kube-secret-manifest | kubectl $(kubectl-options) apply -f -
}

run-action-kube-secret-get() {
    use-karmah-var secret_name
    use-karmah-var secret_field
    log-verbose kube-secret "kubectl $(kubectl-options) get secrets ${secret_name} -o jsonpath=\"{.data.${secret_field}}\""
    local val=$(kubectl $(kubectl-options) get secrets  ${secret_name} -o jsonpath="{.data.${secret_field}}")
    secret_value=$(echo -n $val| base64 -d)
}

run-action-kube-secret-print-field() { run-action-kube-secret-get; echo $secret_value; }
run-action-kube-secret-diff()     { kube-secret-manifest | kubectl $(kubectl-options) diff -f -; }
run-action-kube-secret-manifest() { kube-secret-manifest; }

run-action-kube-secret-save-files() {
    use-karmah-var secret_name
    log-info kube-secret "getting file(s) from secret $secret_name"
    local data=$(kubectl $(kubectl-options) get secret $secret_name -o yaml | yq .data)
    if [[ $data == null ]]; then
        log-error kube-secret "no secret found with name $secret_name"
        exit 1
    fi
    local line; for line in ${data//: /:}; do
        local name=${line/:*/}
        local content=${line//*:/}
        log-info kube-secret "saving $name"
        echo  $content | base64 -d >$name
    done
}

run-action-kube-secret-print-yaml() {
    use-karmah-var secret_name
    log-info kube-secret "getting file(s) from secret $secret_name"
    local data=$(kubectl $(kubectl-options) get secret $secret_name -o yaml | yq .data)
    if [[ $data == null ]]; then
        log-error kube-secret "no secret found with name $secret_name"
        exit 1
    fi
    local line; for line in ${data//: /:}; do
        local name=${line/:*/}
        local content=${line//*:/}
        echo $name: $(echo $content | base64 -d)
    done
}
