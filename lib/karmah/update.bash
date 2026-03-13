
update-init-climah-module() {
    add-karmah-action u update "update source files with expressions from --update"
    add-option V version ver  "specify version (tag) to use for update or scale"
    help_level=expert
    add-option u update expr  "apply a custom update"

    declare -ga updates=()
    argparse_aliases[tmp-start]="kube-tmp-scale --replicas default"
    argparse_aliases[stop]="deploy --replicas 0"
    argparse_aliases[tmp-stop]="kube-tmp-scale --replicas 0"
    argparse_aliases[start]="deploy --replicas default"
}

parse-option-version()  { update_version="$2"; parse_result=2; }
parse-option-update()   { updates+=("$2"); parse_result=2; }

run-action-update() {
    local any_updates=false
    if [[ ! -z ${update_version:-} ]]; then
        #info update $target_name version to $update_version
        ${karmah_type}-update-target-version ${update_version}
        any_updates=true
        git-add-message "version ${update_version}"
    fi
    if [[ ! -z ${kube_replicas:-} ]]; then
        #info update $target_name replicas to $kube_replicas
        ${karmah_type}-update-target-replicas $kube_replicas
        any_updates=true
        git-add-message "replicas ${kube_replicas}"
    fi
    local u
    for u in "${updates[@]}"; do
        verbose custom update function $custom_update_function
        ${karmah_type}-update-target "$u"
        git-add-message "update ${u}"
    done
    $any_updates || verbose no updates specified
}
