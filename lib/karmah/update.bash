
init_climah_module_update() {
    add-action u update "" "update source files with expressions from --update"
    help_level=expert
    add-option V version ver  "specify version (tag) to use for update or scale"
    add-option u update expr  "apply a custom update"

    declare -ga updates=()

    global_vars+=" update_version_function update_replicas_function custom_update_function"
    aliases[tmp-stop]="--action kube-tmp-scale --replicas 0"
    aliases[tmp-start]="--action kube-tmp-scale --replicas default"
    aliases[stop]="--action deploy --replicas 0"
    aliases[start]="--action deploy --replicas default"
}

parse-option-version()  { update_version="$2"; parse_result=2; }
parse-option-update()   { updates+=("$2"); parse_result=2; }

run-action-update() {
    local any_updates=false
    if [[ ! -z ${update_version:-} ]]; then
        #info update $target version to $update_version
        ${update_version_function:-default_update_version}
        any_updates=true
        add_message "version ${update_version}"
    fi
    if [[ ! -z ${kube_replicas:-} ]]; then
        #info update $target replicas to $kube_replicas
        ${update_replicas_function:-default_update_replicas}
        any_updates=true
        add_message "replicas ${kube_replicas}"
    fi
    local u
    for u in "${updates[@]}"; do
        if [[ -z ${custom_update_function:-} ]]; then
            error no update function defined for update $u
            exit 1
        else
            verbose custom update function $custom_update_function
            $custom_update_function "$u"
            add_message "update ${u}"
        fi
    done

    $any_updates || verbose no updates detected
}

default_update_version() {
    local r
    local any_updates=false
    for r in ${renderer//,/ }; do
        if [[ $(type -t update_version_$r) == function ]]; then
            info updating $target version in $r to $update_version
            update_version_$r
            any_updates=true
        else
            debug skipping update version $r
        fi
    done
    $any_updates || warn no updates performed for version to $update_version
}

default_update_replicas() {
    local r
    local any_updates=false
    for r in ${renderer//,/ }; do
        if [[ $(type -t update_replicas_$r) == function ]]; then
            info updating $target replicas in $r to $kube_replicas
            update_replicas_$r
            any_updates=true
        else
            debug skipping update replicas $r
        fi
    done
    $any_updates || warn no updates performed for replicas to $kube_replicas
}
