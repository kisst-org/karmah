kube-bao::init-module() {
    add-module-summary "actions to work with kubernetes secrets from bao"
    #declare-action kbsd kube-bao-secret-diff     "prints the changes to a kubernetes secret"
    #declare-action kbsm kube-bao-secret-manifest "prints the manifest of the secret to be created"

    declare-action kbtp kube-bao-token-print  "print the bao token as stored in kubernetes"
    declare-action kbti kube-bao-token-info   "lookup info of the bao token as stored in kubernetes"
    declare-action kbtu kube-bao-token-update "update a new bao token as stored in kubernetes"
    declare-action kbtr kube-bao-token-revoke "revoke an existing bao token as stored in kubernetes"

    declare-action kbsp kube-bao-secret-id-print  "print the bao secret-id as stored in kubernetes"
    declare-action kbsi kube-bao-secret-id-info   "lookup of the bao secret-id as stored in kubernetes"
    declare-action kbsu kube-bao-secret-id-update "update a new bao secret-id as stored in kubernetes"
}

#######################
# tokens
init-bao-token-vars() {
    if [[ -z ${postfix:-} ]]; then
        kube_secret_name=${kube_bao_token_secret_name:-openbao-token}
    else
        kube_secret_name=${kube_bao_token_secret_name:-openbao-token-$postfix}
    fi
    kube_secret_field=${kube_bao_token_secret_field:-VAULT_TOKEN}
}

action::kube-bao-token-print() {
   init-bao-token-vars
   action::kube-secret-get
   echo "bao token is $secret_value"
}
action::kube-bao-token-info() {
    init-bao-token-vars
    run-actions kube-secret-get,bao-token-info
}
action::kube-bao-token-update() {
    init-bao-token-vars
    if $(log-shows-verbose); then action::kube-secret-get; fi
    run-actions bao-token-update,kube-secret-update
}
action::kube-bao-token-revoke() {
    init-bao-token-vars
    if $(log-shows-verbose); then action::kube-secret-get; fi
    run-actions bao-token-revoke # TODO kube-secret-delete
}


#######################
# secret-id
init-bao-secret-id-vars() {
    if [[ -z ${postfix:-} ]]; then
        kube_secret_name=${kube_bao_secret_id_secret_name:-openbao-approle-secret-id}
    else
        kube_secret_name=${kube_bao_secret_id_secret_name:-openbao-approle-secret-id-$postfix}
    fi
    kube_secret_field=${kube_bao_secret_id_secret_field:-secret-id}
}
action::kube-bao-secret-id-print() {
   init-bao-secret-id-vars
   action::kube-secret-get
   echo "bao secret-id is $secret_value"
}
action::kube-bao-secret-id-info() {
    init-bao-secret-id-vars
    run-actions kube-secret-get,bao-secret-id-info
}
action::kube-bao-secret-id-update() {
    init-bao-secret-id-vars
    if $(log-shows-verbose); then action::kube-secret-get; fi
    run-actions bao-secret-id-update,kube-secret-update
}
