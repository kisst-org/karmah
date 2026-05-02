bao::init-module() {
    add-module-help "actions to work with bao"

    add-value-option "" ttl duration      "set the ttl voor a token, e.g. 30m of 60d"
    # see https://openbao.org/docs/concepts/duration-format/
    local_vars+=" ttl"

    add-karmah-action bli bao-login  "login and store the token in a file"
    add-karmah-action blo bao-logout "remove the file with the login token"

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

action::bao-login() {
    if [[ -f $bao_token_file ]]; then
        local answer
        read -p "token file $bao_token_file already exist, do you want to login anyway [Y/n]? " answer
        if [[ "${answer}" == n ]] ;then
            log-info bao "Stopping bao login"
            exit 1
        fi
    fi
    local token=$(bao login $bao_options $bao_login_options  -no-store -field token  $bao_login_params )
    mkdir -p $(dirname ${bao_token_file})
    echo $token >${bao_token_file}
    chmod 600 ${bao_token_file}
}
action::bao-logout() { rm -f $bao_token_file; }
export-bao-login-token() { export VAULT_TOKEN=$(<$bao_token_file); }
run-bao() {
    local cmd=$1; shift
    export-bao-login-token
    log-info bao "bao $cmd $bao_options \"${@}\""
    bao $cmd $bao_options "${@}"
}

#######################
# tokens
action::bao-token-info() {
    local error
    local token=$secret_value
    exitcode=0
    if $(log-shows-warn); then
        run-bao "token lookup" $token || exitcode=$?
        if [[ $exitcode == 2 ]]; then
            log-warn bao "bao token lookup exitcode 2: invalid token $token, probably expired token stored in secret"
        elif [[ $exitcode != 0 ]]; then
            log-warn bao "bao token lookup exitcode $exitcode: maybe permission denied"
        fi
    else
        # same command, but no errors printed
        run-bao "token lookup" $token 2>/dev/null || exitcode=$?
    fi
}

action::bao-token-create() {
    local ttl=$(get-option-value ttl 30m)
    secret_value=$(run-bao "token create"  -ttl=$ttl -format=yaml | yq .auth.client_token)
}

action::bao-token-update() {
    if $(log-shows-verbose); then
        echo ======== OLD TOKEN ============
        action::bao-token-info
        echo ==== creating new token in Secret
    fi
    action::bao-token-create
    if $(log-shows-verbose); then
        echo ======== NEW TOKEN ============
        action::bao-token-info
    fi
}

#######################
# secret-id's
action::bao-secret-id-create() {
    secret_value=$(run-bao write -force -format=yaml auth/approle/role/$(bao-role-name)/secret-id | yq .data.secret_id)
    log-info bao "created secret-id $secret_value"
}
action::bao-secret-id-info() {
    local error
    exitcode=0
    if [[ -z ${secret_value:-} ]]; then
        secret_value=$argparse_extra_args
    fi
    log-info bao "lookup secret-id: $secret_value # TODO log-sensitive-info"
    if $(log-shows-warn); then
        log-verbose bao "write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_id=$secret_value"
        run-bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_id=$secret_value || exitcode=$?
        if [[ $exitcode == 2 ]]; then
            log-warn bao "bao token lookup exitcode 2: invalid secret-id $secret_value, probably expired token stored in secret"
        elif [[ $exitcode != 0 ]]; then
            log-warn bao "bao token lookup exitcode $exitcode: maybe permission denied"
        fi
    else
        # same command, but no errors printed
        run-bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_value=$secret_value 2>/dev/null || exitcode=$?
    fi
}
action::bao-secret-id-list()   {
    run-bao list auth/approle/role/$(bao-role-name)/secret-id
    if $(log-shows-verbose); then
        for id in $(bao list auth/approle/role/$(bao-role-name)/secret-id| tail -n +3); do
            echo ======= $id
            bao write auth/approle/role/$(bao-role-name)/secret-id/lookup secret_value=$id
        done
    fi
}
action::bao-secret-id-update() {
    if $(log-shows-verbose); then
        echo ======== OLD SECRET_ID ============
        action::bao-secret-info
        echo ==== creating new token in Secret
    fi
    secret_value=$(bao-create-secret-id)
    log-verbose bao "created secret-id $secret_value"
    action::bao-secret-update
    if $(log-shows-verbose); then
        echo ======== NEW TOKEN ============
        action::bao-secret-info
    fi
}

action::bao-secret-id-create() {
    if $(log-shows-verbose); then
        run-cmd-from-action verbose bao write -force auth/approle/role/$(bao-role-name)/secret-id
    else
        echo $(bao-secret-create)
    fi
}

#######################
# roles

bao-role-name()     { echo -n external-secret-$postfix; }
bao-role-id()       { run-bao read -format=yaml auth/approle/role/$(bao-role-name)/role-id | yq .data.role_id; }
bao-role-policies() { run-bao read -format=yaml auth/approle/role/$(bao-role-name) | yq '.data.token_policies[]'; }

action::bao-role-list() { run-bao list auth/approle/role; }
action::bao-role-info() {
    echo "role-name: $(bao-role-name)"
    echo "role-id:   $(bao-role-id)"
    run-bao read auth/approle/role/$(bao-role-name)
}
action::bao-role-create() {
    run-bao write auth/approle/role/external-secret-$postfix  token_policies="$bao_token_policies"
}

#######################
# policies

action::bao-policy-create() {
    bao policy write read-kv-$postfix - <<EOF
{
    "path": {
        "kv-$postfix/*": {"capabilities": ["read"]}
        "auth/*": {"capabilities": ["read"]}
    }
}
EOF
}

action::bao-policy-info() { run-cmd-from-action verbose bao policy read read-kv-$postfix; }

# TODO: action::bao-role-login() { bao write auth/approle/login role_id= secret_id=... }
