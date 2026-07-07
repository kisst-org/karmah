
update::init-module() {
    add-module-summary "actions to update source files for rendering e.g. (helm values)"
    declare-action u update "update source files with expressions from --update"
    add-karmah-var    V version '<tag>'  "specify version (image tag) to use for update"
    help_level=expert
    add-func-option u update '<expr>'  "apply a custom update"

    declare -ga updates=()
    argparse_aliases[tmp-start]="kube-tmp-scale --replicas default"
    argparse_aliases[stop]="deploy --replicas 0"
    argparse_aliases[tmp-stop]="kube-tmp-scale --replicas 0"
    argparse_aliases[start]="deploy --replicas default"
}

option::update()   { updates+=("$2"); argparse_parse_count=2; }

action::update() {
    use-karmah-var replicas
    use-karmah-var version
    local any_updates=false
    if [[ ! -z ${version:-} ]]; then
        log-info update "update version to $version"
        ${karmah_type}::update-target-version ${version}
        any_updates=true
        git-add-message "version ${version}"
    fi
    if [[ ! -z ${replicas:-} ]]; then
        log-info update "update replicas to $replicas"
        ${karmah_type}::update-target-replicas $replicas
        any_updates=true
        git-add-message "replicas ${replicas}"
    fi
    local u
    for u in "${updates[@]}"; do
        log-info update "custom update function $custom_update_function"
        ${karmah_type}::update-target "$u"
        git-add-message "update ${u}"
    done
    $any_updates || log-verbose update "no updates specified"
}
