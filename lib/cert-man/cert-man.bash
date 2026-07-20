cert-man::init-module() {
    add-module-summary "actions to work with cert-manager cli cmctl"

    add-karmah-var "" cert_name   name "the name of a certificate"
    add-karmah-var "" cert_secret name "the name where the secret is stored"

    declare-action cis cmctl-inspect-secret "inspect (show) the details of a certificate stored in a secret"
    declare-action cr  cmctl-renew          "renew a certificate"
}

action::cmctl-inspect-secret() {
    action-log info "running cmctl inspect secret for $target_name"
    run-verbose-cmd cmctl inspect secret --context $kube_context --namespace $kube_namespace $cert_secret || true
}

action::cmctl-renew() {
    action-log info "running cmctl renew"
    run-verbose-cmd cmctl renew --context $kube_context --namespace $kube_namespace $cert_name
}
