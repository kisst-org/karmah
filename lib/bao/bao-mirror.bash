
bao-mirror::init-module() {
    add-module-summary "actions to copy and compare keys in two bao vaults"

    declare-action bda bao-diff-all      "diff all keys between bao_from vault and bao_to vault"
    declare-action BCF bao-copy-from "copy all keys from other vault"
    # declare-action BCT bao-copy-to   "copy all keys to other vault"
    # declare-action be  bao-export    "export all keys from vault to a file"
    # declare-action bi  bao-import    "import all keys from a file to vault"

    add-karmah-var  ""  bao_path         "a path to copy or diff"
    add-karmah-var  ""  bao_other_vault  "the other vault to copy from or comapre with"
    add-karmah-var  ""  bao_keys         "selection of keys to be used"
}

bao::get-json() { local path=$1; run-bao "kv get" -format=json -field=data $path; }
bao::put-json() { local path=$1; run-bao "kv put" $path -; }
bao::postfix-exists() {
    local path=$1 postfix=$2
    local list=$(bao-list-path $path | grep "^$postfix\$" || true)
    [[ ! -z $list ]]
}


bao-list-path() {
    local path=$1
    run_in_check_mode=true
    run-bao "kv list" $path| tail -n +3 | sort
}

action::bao-copy-from () {
    use-karmah-var bao_other_vault
    use-karmah-var bao_keys
    declare -A map="${bao_map_path:-}"
    local map_list=${bao_map_keys:-}
    local m; for m in ${map_list//,/ }; do
        map[${m//:*/}]=${m//*:/}
    done
    local paths=${bao_keys//,/ };
    if [[ -z $paths ]];then
        paths=$(bao_vault=$bao_other_vault bao-list-path $bao_other_prefix)
    fi
    local p; for p in $paths; do
        p=${p%/}
        local from=$bao_other_prefix/$p
        local to=$bao_prefix/${map[$p]:-$p}
        if [[ $to == "$bao_prefix/IGNORE" ]]; then
            log-info bao "ignoring $from because of mapping"
        elif $(bao_vault=$bao_other_vault bao::postfix-exists $from "$bao_other_postfix"); then
            log-info bao "copying $from/$bao_other_postfix ==> $to"
            bao_vault=$bao_other_vault bao::get-json $from/$bao_other_postfix | bao::put-json $to
        else
            log-info bao "skipping $from because there is no $bao_other_postfix subpath"
        fi
    done
}

action::bao-diff-all() {
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
            # ignore_cmd_exit_code=true
            local json_other="$(run-bao "kv get" -format=json -field=data $path2)"
            if [[ -z $json_other ]]; then
                echo missing $path2
            elif [[ "$json_other" == "$json_from" ]]; then
                log-verbose bao-diff "identical $p and $path2"
            else
                echo changes found between path $p and $path2
                diff <(printf "%s\n" "${json_from}") <(printf "%s\n" "${json_other}") || true
            fi
        fi
    done
}
