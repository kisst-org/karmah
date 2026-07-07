bao-approle::init-module() {
    add-module-summary "actions to work with bao approles and secret-id's"
    add-karmah-var a  accessor  uid "bao secret-id/token accessor"
    add-karmah-var "" secret_id uid "bao secret-id"

    declare-action bsl  bao-secret-id-list    "list all secret-id's for an approle"
    declare-action bsi  bao-secret-id-info    "lookup the details of a secret-id for an approle in bao"
    declare-action bsc  bao-secret-id-create  "create a new secret-id for an approle in bao"
    declare-action bsd  bao-secret-id-destroy "destroy a new secret-id for an approle in bao"
    #declare-action ""   bao-secret-id-rm-all  "remove all known approle secret-id's"

    declare-action brl  bao-role-list      "list all approles"
    declare-action bri  bao-role-info      "lookup the info of an approle"
    declare-action brc  bao-role-create    "create a new approle"

    declare-action bpi  bao-policy-info  "lookup the details of a bao policy"
    declare-action bpc  bao-policy-create  "create a bao policy"


}

#######################
# secret-id's
action::bao-secret-id-create() {
    secret_value=$(run-bao write -force -format=yaml auth/approle/role/$(bao-role-name)/secret-id | yq .data.secret_id)
    log-info bao "created secret-id $secret_value"
}
action::bao-secret-id-info() {
    use-karmah-var secret_value
    use-karmah-var accessor
    local error
    exitcode=0
    local field=secret-id-accessor
    local key=$accessor
    if [[ -z $accessor ]]; then
        field=secret-id
        key=$secret_value
        log-info bao "lookup $field: ..."
    else
        log-info bao "lookup $field: $key"
    fi
    if $(log-shows-warn); then
        run-bao write auth/approle/role/$(bao-role-name)/$field/lookup ${field//-/_}=$key || exitcode=$?
        if [[ $exitcode == 2 ]]; then
            log-warn bao "bao token lookup exitcode 2: invalid $field $key, probably expired secret-id"
        elif [[ $exitcode != 0 ]]; then
            log-warn bao "bao token lookup exitcode $exitcode: maybe permission denied"
        fi
    else
        # same command, but no errors printed
        run-bao write auth/approle/role/$(bao-role-name)/$field/lookup ${field//-/_}=$key 2>/dev/null || exitcode=$?
    fi
}
action::bao-secret-id-list()   {
    run-bao list auth/approle/role/$(bao-role-name)/secret-id
    if $(log-shows-verbose); then
        for id in $(run-bao list auth/approle/role/$(bao-role-name)/secret-id| tail -n +3); do
            echo ======= $id
            run-bao write auth/approle/role/$(bao-role-name)/secret-id-accessor/lookup secret_id_accessor=$id
        done
    fi
}
action::bao-secret-id-destroy() {
    use-karmah-var accessor
    run-bao write auth/approle/role/$(bao-role-name)/secret-id-accessor/destroy secret_id_accessor=$accessor
}
action::bao-secret-id-update() {
    if $(log-shows-verbose); then
        echo ======== OLD SECRET_ID ============
        action::bao-secret-info
        echo ==== creating new token in Secret
    fi
    secret_value=$(bao-create-secret-id)
    log-info bao "created secret-id $secret_value"
    action::bao-secret-update
    if $(log-shows-verbose); then
        echo ======== NEW TOKEN ============
        action::bao-secret-info
    fi
}

action::bao-secret-id-create() {
    if $(log-shows-verbose); then
        run-verbose-cmd bao write -force auth/approle/role/$(bao-role-name)/secret-id
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

action::bao-policy-info() { run-verbose-cmd bao policy read read-kv-$postfix; }

# TODO: action::bao-role-login() { bao write auth/approle/login role_id= secret_id=... }
