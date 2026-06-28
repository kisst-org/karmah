
bao-mirror::init-module() {
    add-module-help "actions to copy and compare keys in two bao vaults"

    declare-action bd bao-diff    "diff all keys between bao_from vault and bao_to vault"
    declare-action bc bao-copy    "copy all keys from bao_from vault to bao_to vault"
    declare-action be bao-export  "export all keys from bao_from vault to a file"
    declare-action bi bao-import  "import all keys from a file to bao_to vault"

    add-karmah-var  ""  bao_path                "a path to copy or diff"
}

action::bao-diff() {
    use-karmah-var bao_path
    if [[ -z $bao_path ]]; then
        run-bao-diff $(run-bao "kv list" $bao_prefix| tail -n +3 | sort)
    else
        run-bao-diff $bao_path
    fi
}

run-bao-diff() {
    local paths="$@"
    local result=""
    local _orig_vault=$bao_vault
    local p; for p in $paths; do
        local bao_vault=$_orig_vault
        local path1=$bao_prefix/$p
        # TODO $bao_postfix handling
        local json_from="$(run-bao "kv get" -format=json -field=data $path1)"
        if [[ -z $json_from ]]; then
            log-verbose bao-diff "skipping $p"
        else
            result+=" $p"
            bao_vault=$bao_other_vault
            local path2=$bao_other_prefix/$p
            if [[ ! -z $bao_other_postfix ]]; then
                path2=$path2/$bao_other_postfix
            fi
            local json_other="$(run-bao "kv get" -format=json -field=data $path2)"
            if [[ "$json_other" == "$json_from" ]]; then
                log-verbose bao-diff "identical $p and $path2"
            else
                echo changes found between path $p and $path2
                diff <(printf "%s\n" "${json_from}") <(printf "%s\n" "${json_other}") || true
            fi
        fi
    done
}


action::bao-copy() {
    echo TODO
}
action::bao-import() {
    echo TODO
}
action::bao-export() {
    echo TODO
}
