bao::init-module() {
    add-module-summary "actions to work with bao"

    # see https://openbao.org/docs/concepts/duration-format/
    add-karmah-var "" ttl      duration   "set the ttl voor a token, e.g. 30m of 60d"
    add-karmah-var "" bao_addr url        "address (url) to use for openbao"
    add-karmah-var g  grep     pat        "get/grep a pattern/field from the lookup info"

    declare-action bli bao-login  "login and store the token in a file"
    declare-action blo bao-logout "remove the file with the login token"
    declare-action blv bao-login-vars  "show the vars you can export"
    declare-action bgy bao-get-yaml    "get the values of path and show in yaml format"
    declare-action bgx bao-get-export  "get the values of path and show in format to export env vars"
}

#######################
# login
action::bao-login() {
    local bao_token_file=${bao_token_file:-./tmp/bao/${bao_vault}.token}
    if [[ -f $bao_token_file ]]; then
        local answer
        read -p "token file $bao_token_file already exist, do you want to login anyway [Y/n]? " answer
        if [[ "${answer}" == n ]] ;then
            log-info bao "Stopping bao login"
            exit 1
        fi
    fi
    $bao_login_dialog_func
    # echo "Enter password for ${bao_login_params} (will not been shown):"
    local token=$(run-bao-tokenless login $bao_login_options  -no-store -field token  $bao_login_params) # 2>/dev/null)
    mkdir -p $(dirname ${bao_token_file})
    run-verbose-cmd echo $token \| tee ${bao_token_file}
    run-verbose-cmd chmod 600 ${bao_token_file}
    log-info bao "token saved to $bao_token_file"
}

action::bao-logout() { rm -f $bao_token_file; } # TODO: revoke token

action::bao-login-vars() {
    use-karmah-var bao_addr
    log-info bao "export the following vars. This can be done with:"
    log-info bao "    eval \$($climah_prog_path $target_path bao-login-vars -q)"
    echo export VAULT_ADDR=${bao_addr}
    echo export VAULT_TOKEN=$(<$bao_token_file)
    if [[ ! -z ${bao_namespace:-} ]]; then
        echo export VAULT_NAMESPACE=${bao_namespace}
    fi
}

calc-bao-token() {
    local vault=$1
    local bao_token_file=./tmp/bao/${vault}.token
    local bao_token_var=BAO_TOKEN_${vault//-/_}
    log-info bao "calc token using var ${bao_token_var} and file ${bao_token_file}"
    bao_token_var=${bao_token_var^^}
    if [[ ! -z ${!bao_token_var:-} ]]; then
        log-debug bao "using token var $bao_token_var"
        echo {!bao_token_var}
    elif [[ -f ${bao_token_file:-.} ]]; then # the . dir is never a file
        log-debug bao "using token file  $bao_token_file"
        # use token from login mechanism
        echo $(<$bao_token_file)
    elif [[ -z ${VAULT_TOKEN:-} ]]; then
        echo $VAULT_TOKEN
    else
        log-error bao "could not determine bao token, either set {bao_token_var:-VAULT_TOKEN} or do a bao-login action"
    fi
}


run-bao() { VAULT_TOKEN=$(${calc_bao_token_func:-calc-bao-token} $bao_vault) run-bao-tokenless "$@"; }
run-bao-tokenless() {
    local cmd=$1; shift  # the cmd can be multiple words, like "kv list" that need to come before the options
    run-verbose-cmd bao $cmd $($bao_calc_vault_options_func $bao_vault) "$@"
}


action::bao-get-yaml() { run-bao "kv get" -field=data -format=yaml $bao_path; }

action::bao-get-export() {
    log-info bao "export the following vars. This can be done with:"
    log-info bao "    eval \$($climah_prog_path $target_path bao-get-export -q)"
    run-bao "kv get" -field=data -format=yaml $bao_path | sed -e "s/: /='/" -e 's/^/export /' -e "s/$/'/"
}
