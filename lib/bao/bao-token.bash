bao-token::init-module() {
    add-module-help "actions to work with bao tokens"

    local action_params="[tok/acc]"
    declare-action btc  bao-token-create     "create a new token"
    declare-action bti  bao-token-info       "lookup the details of a token"
    declare-action btr  bao-token-revoke     "revoke an existing token"
    action_params=""
    declare-action btl  bao-token-list       "list all token accessor"
    declare-action btli bao-token-list-info  "list details of all token accessor"
}

action::bao-token-info() {
    use-karmah-var grep
    local token="${*:-}"
    if [[ -z ${token} ]]; then
        use-karmah-var secret_value
        token=$secret_value
    fi
    local error
    local exitcode=0
    if $(log-shows-warn); then
        if [[ -z $grep ]]; then
            run-bao "token lookup" $token || exitcode=$?
        else
            run-bao "token lookup" $token | grep ttl
        fi
        if [[ $exitcode == 2 ]]; then
            log-warn bao "bao token lookup exitcode 2: invalid token, probably expired token"
        elif [[ $exitcode != 0 ]]; then
            log-warn bao "bao token lookup exitcode $exitcode: maybe permission denied"
        fi
    else
        # same command, but no errors printed
        run-bao "token lookup" $token 2>/dev/null || exitcode=$?
    fi
}

action::bao-token-create() {
    use-karmah-var ttl 30m
    #bao token create -ttl=$ttl -format=yaml
    secret_value=$(run-bao "token create" -orphan -ttl=$ttl -format=yaml | yq .auth.client_token)
}
action::bao-token-revoke() {
    use-karmah-var accessor
    run-bao "token revoke" -accessor $accessor
}
action::bao-token-list() { run-bao list auth/token/accessors | tail -n +3; }
action::bao-token-list-info() {
    local accessors=$(action::bao-token-list)
    use-karmah-var grep
    local acc; for acc in $accessors; do
        echo ======= $acc
        #run-bao "token lookup" -accessor $acc 2>/dev/null || exitcode=$?
        if [[ -z $grep ]]; then
            action::bao-token-info "-accessor $acc"
        else
            action::bao-token-info "-accessor $acc" | grep $grep
        fi
    done
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
