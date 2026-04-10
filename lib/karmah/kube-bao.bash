kube-bao::init-climah-module() {
    module-add-help "actions to work with kubernetes secrets from bao"
    #add-karmah-action kbsd kube-bao-secret-diff     "prints the changes to a kubernetes secret"
    #add-karmah-action kbsm kube-bao-secret-manifest "prints the manifest of the secret to be created"

    add-karmah-action kbtp kube-bao-token-print  "print the bao token as stored in kubernetes"
    add-karmah-action kbti kube-bao-token-info   "lookup info of the bao token as stored in kubernetes"
    add-karmah-action kbtu kube-bao-token-update "update a new bao token as stored in kubernetes"

    add-karmah-action kbsp kube-bao-secret-id-print  "print the bao secret-id as stored in kubernetes"
    add-karmah-action kbsi kube-bao-secret-id-info   "lookup of the bao secret-id as stored in kubernetes"
    add-karmah-action kbsu kube-bao-secret-id-update "update a new bao secret-id as stored in kubernetes"
}

#######################
# tokens
init-bao-token-vars() {
    if [[ -z ${postfix:-} ]]; then
        kube_secret_name=${kube_bao_token_secret_name:-openbao-token}
    else
        kube_secret_name=${kube_bao_token_secret_name:-openbao-token-$postfix}
    fi
    kube_secret_field=${kube_bao_token_secret_field:-token}
}

run-action-kube-bao-token-print() {
   init-bao-token-vars
   run-action-kube-secret-get
   echo "bao token is $secret_value"
}
run-action-kube-bao-token-info() {
    init-bao-token-vars
    run-flow-actions kube-secret-get,bao-token-info
}
run-action-kube-bao-token-update() {
    init-bao-token-vars
    if $(log-is-verbose); then run-action-kube-secret-get; fi
    run-flow-actions bao-token-update,kube-secret-update
}

#######################
# secret-id
init-bao-secret-id-vars() {
    if [[ -z ${postfix:-} ]]; then
        kube_secret_name=${kube_bao_secret_id_secret_name:-openbao-secret-id}
    else
        kube_secret_name=${kube_bao_secret_id_secret_name:-openbao-secret-id-$postfix}
    fi
    kube_secret_field=${kube_bao_secret_id_secret_field:-secret-id}
}
run-action-kube-bao-secret-id-print() {
   init-bao-secret-id-vars
   run-action-kube-secret-get
   echo "bao secret-id is $secret_value"
}
run-action-kube-bao-secret-id-info() {
    init-bao-secret-id-vars
    run-flow-actions kube-secret-get,bao-secret-id-info
}
run-action-kube-bao-secret-id-update() {
    init-bao-secret-id-vars
    if $(log-is-verbose); then run-action-kube-secret-get; fi
    run-flow-actions bao-secret-id-update,kube-secret-update
}
