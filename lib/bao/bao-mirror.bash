
bao-mirror::init-module() {
    add-module-help "actions to copy and compare keys in two bao vaults"

    declare-action bd bao-diff    "diff all keys between bao_from vault and bao_to vault"
    declare-action bc bao-copy    "copy all keys from bao_from vault to bao_to vault"
    declare-action be bao-export  "export all keys from bao_from vault to a file"
    declare-action bi bao-import  "import all keys from a file to bao_to vault"

    add-karmah-var  ""  bao_from_addr            "the addres of the vault to copy/compare from"
    add-karmah-var  ""  bao_from_token_var         "the environment var containing a token to authenticate in the vault to copy/compare from"
    add-karmah-var  ""  bao_from_namespace       "the namespace of the vault to copy/compare from"
    add-karmah-var  ""  bao_from_path            "the path in the from_vault"
    add-karmah-var  ""  bao_from_postfix       "a postfix to remove from each path in the from_vault"
    add-karmah-var  ""  bao_to_addr              "the addres of the vault to copy/compare to"
    add-karmah-var  ""  bao_to_token_var         "the environment var containing a token to authenticate in the vault to copy/compare to"
    add-karmah-var  ""  bao_to_namespace         "the namespace of the vault to copy/compare to"
    add-karmah-var  ""  bao_to_path              "the path in the to_vault"
    add-karmah-var  ""  bao_to_postfix          "a postfix to add to each path in the to_vault"
    add-karmah-var  ""  bao_to_postfix          "a postfix to add to each path in the to_vault"
    add-karmah-var  ""  bao_path                "a path to copy or diff"
    # add-karmah-var  ""  bao_map_entire_path      ""
    # add-karmah-var  ""  bao_map_stripped_path    ""
}

run-bao-from() {
    local cmd=$1; shift
    if [[ -z ${bao_from_namespace:-} ]]; then
        VAULT_TOKEN=${!bao_from_token_var} run-verbose-cmd bao $cmd -address=$bao_from_addr "$@"
    else
        VAULT_TOKEN=${!bao_from_token_var} run-verbose-cmd bao $cmd -address=$bao_from_addr -ns=$bao_from_namespace "$@"
    fi
}
run-bao-to() {
    local cmd=$1; shift
    if [[ -z ${bao_to_namespace:-} ]]; then
        VAULT_TOKEN=${!bao_to_token_var} run-verbose-cmd bao $cmd -address=$bao_to_addr "$@"
    else
        VAULT_TOKEN=${!bao_to_token_var} run-verbose-cmd bao $cmd -address=$bao_to_addr -ns=$bao_to_namespace "$@"
    fi
}
# run-bao-to() {
#     if [[ -z ${bao_to_namespace:-} ]]; then
#         VAULT_TOKEN=${!bao_to_token_var} VAULT_ADDR=$bao_to_addr run-verbose-cmd bao "$@"
#     else
#         log-verbose bao "VAULT_TOKEN=${!bao_to_token_var} VAULT_ADDR=$bao_to_addr VAULT_NAMESPACE=$bao_to_namespace run-verbose-cmd bao \"$@\""
#         VAULT_TOKEN=${!bao_to_token_var} VAULT_ADDR=$bao_to_addr VAULT_NAMESPACE=$bao_to_namespace run-verbose-cmd bao "$@"
#     fi
# }
action::bao-diff() {
    use-karmah-var bao_path

    local from_paths=$bao_path
    if [[ -z $from_paths ]]; then
        from_paths=$(run-bao-from "kv list" $bao_from_path | tail -n +3 | sort)
    fi
    run-bao-diff
}

run-bao-diff() {
    local result=""
    local p
    for p in $from_paths; do
        local json_from="$(run-bao-from "kv get" -format=json -field=data $bao_from_path/$p/$bao_from_postfix)"
        if [[ -z $json_from ]]; then
            log-verbose bao-diff "skipping $p"
        else
            result+=" $p"
            local json_to="$(run-bao-to "kv get" -format=json -field=data $bao_to_path/$p/$bao_to_postfix)"
            if [[ "$json_to" == "$json_from" ]]; then
                log-verbose bao-diff "identical $p"
            else
                echo changes found in path $p
                # local eol=$'\n'
                diff <(printf "%s\n" "${json_from}") <(printf "%s\n" "${json_to}") || true
                # printf "FROM %s" "${json_from}"
            fi
        fi
    done
    #echo "$result"
}


# action::bao-diff() {
#     local from_paths=$(get-bao-from-paths)
#     local to_paths=$(run-bao-to kv list $bao_to_path | tail -n +3 | sort)
#     echo FROM $from_paths
#     echo TO $to_paths
# }
action::bao-copy() {
    echo TODO
}
action::bao-import() {
    echo TODO
}
action::bao-export() {
    echo TODO
}
