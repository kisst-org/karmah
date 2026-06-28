bao::init-module() {
    add-module-help "actions to work with bao"

    # see https://openbao.org/docs/concepts/duration-format/
    add-karmah-var "" ttl      duration   "set the ttl voor a token, e.g. 30m of 60d"
    add-karmah-var "" bao_addr url        "address (url) to use for openbao"
    add-karmah-var g  grep     pat        "get/grep a pattern/field from the lookup info"

    declare-action bli bao-login  "login and store the token in a file"
    declare-action blo bao-logout "remove the file with the login token"
    declare-action blv bao-login-vars  "show the vars you can export"
}

#######################
# login
action::bao-login() {
    if [[ -f $bao_token_file ]]; then
        local answer
        read -p "token file $bao_token_file already exist, do you want to login anyway [Y/n]? " answer
        if [[ "${answer}" == n ]] ;then
            log-info bao "Stopping bao login"
            exit 1
        fi
    fi
    echo "Enter password for ${bao_login_params} (will not been shown):"
    local token=$(run-verbose-cmd bao login $bao_options $bao_login_options  -no-store -field token  $bao_login_params 2>/dev/null)
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

# run-bao() {
#     local cmd=$1; shift
#     if [[ ! -z ${bao_token_var:-} ]]; then
#         export VAULT_TOKEN=${!bao_token_var}
#     else
#         # use token from login mechanism
#         export VAULT_TOKEN=$(<$bao_token_file)
#     fi
#     run-verbose-cmd bao $cmd $bao_options ${*}
# }


run-bao() {
    local cmd=$1; shift
    local bao_addr bao_token_var bao_namespace bao_prefix bao_postfix
    ${karmah_type}::calc-bao-vars $bao_vault
    if [[ -z ${bao_namespace:-} ]]; then
        VAULT_TOKEN=${!bao_token_var} run-verbose-cmd bao $cmd -address=$bao_addr "$@"
    else
        VAULT_TOKEN=${!bao_token_var} run-verbose-cmd bao $cmd -address=$bao_addr -ns=$bao_namespace "$@"
    fi
}
