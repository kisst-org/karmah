bao::init-climah-module() {
    add-value-option "" ttl duration      "set the ttl voor a token, e.g. 30m of 60d"
    # see https://openbao.org/docs/concepts/duration-format/
    local_vars+=" ttl"

    add-karmah-action bti bao-token-info   "lookup the details of a token"
    add-karmah-action btr bao-token-update "create a new token"

    add-karmah-action bsl  bao-secret-id-list    "list all secret-id's for an approle"
    add-karmah-action bsi  bao-secret-id-info    "lookup the details of a secret-id for an approle in bao"
    add-karmah-action bsc  bao-secret-id-create  "create a new secret-id for an approle in bao"
    #add-karmah-action ""   bao-secret-id-rm-all  "remove all known approle secret-id's"

    add-karmah-action brl  bao-role-list      "list all approles"
    add-karmah-action bri  bao-role-info      "lookup the info of an approle"
    add-karmah-action brc  bao-role-create    "create a new approle"

    add-karmah-action bpi  bao-policy-info  "lookup the details of a bao policy"
    add-karmah-action bpc  bao-policy-create  "create a bao policy"
}

#######################
# tokens
run-action-bao-token-info() {
    local error
    local token=$secret_value
    exitcode=0
    if $(log-is-warn); then
        bao token lookup $token || exitcode=$?
        if [[ $exitcode == 2 ]]; then
            warn bao token lookup exitcode 2: invalid token $token, probably expired token stored in secret
        elif [[ $exitcode != 0 ]]; then
            warn bao token lookup exitcode $exitcode: maybe permission denied
        fi
    else
        # same command, but no errors printed
        bao token lookup $token 2>/dev/null || exitcode=$?
    fi
}

run-action-bao-token-create() {
    : ${ttl:=${default_ttl:=30m}}
    secret_value=$(bao token create  -ttl=$ttl -format=yaml | yq .auth.client_token)
}

run-action-bao-token-update() {
    if $(log-is-verbose); then
        echo ======== OLD TOKEN ============
        run-action-bao-token-info
        echo ==== creating new token in Secret
    fi
    run-action-bao-token-create
    if $(log-is-verbose); then
        echo ======== NEW TOKEN ============
        run-action-bao-token-info
    fi
}

#######################
# secret-id's
run-action-bao-secret-id-create() {
    secret_value=$(bao write -force -format=yaml auth/approle/role/$(bao-role-name)/secret-id | yq .data.secret_id)
    info created secret-id $secret_value
}
run-action-bao-secret-id-info() {
    local error
    exitcode=0
    if [[ -z ${secret_value:-} ]]; then
        secret_value=$argparse_extra_args
    fi
    info lookup secret-id: $secret_value # TODO log-sensitive-info
    if $(log-is-warn); then
        verbose bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_id=$secret_value
        bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_id=$secret_value || exitcode=$?
        if [[ $exitcode == 2 ]]; then
            warn bao token lookup exitcode 2: invalid secret-id $secret_value, probably expired token stored in secret
        elif [[ $exitcode != 0 ]]; then
            warn bao token lookup exitcode $exitcode: maybe permission denied
        fi
    else
        # same command, but no errors printed
        bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_value=$secret_value 2>/dev/null || exitcode=$?
    fi
}
run-action-bao-secret-id-list()   {
    bao list auth/approle/role/$(bao-role-name)/secret-id
    if $(log-is-verbose); then
        for id in $(bao list auth/approle/role/$(bao-role-name)/secret-id| tail -n +3); do
            echo ======= $id
            bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_value=$id
        done
    fi
}
run-action-bao-secret-id-update() {
    #: ${ttl:=30m}
    if $(log-is-verbose); then
        echo ======== OLD SECRET_ID ============
        run-action-bao-secret-info
        echo ==== creating new token in Secret
    fi
    secret_value=$(bao-create-secret-id)
    verbose created secret-id $secret_value
    run-action-bao-secret-update
    if $(log-is-verbose); then
        echo ======== NEW TOKEN ============
        run-action-bao-secret-info
    fi
}

run-action-bao-secret-id-create() {
    if $(log-is-verbose); then
        verbose-cmd bao write -force auth/approle/role/$(bao-role-name)/secret-id
    else
        echo $(bao-secret-create)
    fi
}

#######################
# roles

bao-role-name()     { echo -n external-secret-$postfix; }
bao-role-id()       { bao read -format=yaml auth/approle/role/$(bao-role-name)/role-id | yq .data.role_id; }
bao-role-policies() { bao read -format=yaml auth/approle/role/$(bao-role-name) | yq '.data.token_policies[]'; }

run-action-bao-role-list() { verbose-cmd bao list auth/approle/role; }
run-action-bao-role-info() {
    echo "role-name: $(bao-role-name)"
    echo "role-id:   $(bao-role-id)"
    verbose-cmd bao read auth/approle/role/$(bao-role-name)
}
run-action-bao-role-create() {
    bao write auth/approle/role/external-secret-$postfix  token_policies="$bao_token_policies"
}

#######################
# policies

run-action-bao-policy-create() {
    bao policy write read-kv-$postfix - <<EOF
{
    "path": {
        "kv-$postfix/*": {"capabilities": ["read"]}
        "auth/*": {"capabilities": ["read"]}
    }
}
EOF
}

run-action-bao-policy-info() { verbose-cmd bao policy read read-kv-$postfix; }

# TODO: run-action-bao-role-login() { bao write auth/approle/login role_id= secret_id=... }
