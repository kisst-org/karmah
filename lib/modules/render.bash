
render::init-module() {
    add-module-summary "actions to render manifests"
    declare -g to_dir

    add-karmah-var "" renderer tool "tool used to render (e.g. helm, kustomize or ytt)"
    add-karmah-var "" manifest_dir dir "directory where manifests are rendered"
    # TODO: redesign manifest_dir that is input to many actions, and --to

    declare-action r render "render manifests to --to <path> (default tmp/manifests)"

    help_level=expert
    declare-action "" compare   "render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)"
    declare-action rm render-rm "remove all rendered manifests"

    add-func-option "" to    path  "other path to render to (default is deployed/manifests)"
    add-func-option "" with  path  "used for comparison between two manifest trees"
    add-flag-option T  tmp         "render to tmp/manifests (already default), do not commit"

}

option::to()        { to_dir="${2%%/}"; argparse_parse_count=2; }
option::with()      { with_dir="${2%%/}"; argparse_parse_count=2; }

action::render() {
    run-pre-actions update
    local tmp=$(get-option-value tmp false)
    manifest_dir="${to_dir:-tmp/manifests}/${target_name}"
    log-info render "render with ${renderer} to ${manifest_dir}"
    run-verbose-cmd rm -rf ${manifest_dir}
    run-verbose-cmd mkdir -p ${manifest_dir}
    change-paths $manifest_dir
    for r in ${renderer//,/ }; do
        render-$r
    done
}

action::render-rm() {
    log-info render "removing  ${target_name} manifests in ${manifest_dir}"
    run-verbose-cmd rm -rf ${manifest_dir}
}


action::compare() {
    olddir=${manifest_dir}
    local newdir=${with_dir:-deployed/manifests}/${target_name}
    log-info render "comparing ${target_name}: ${manifest_dir} with ${newdir}"
    run-verbose-cmd diff -r $newdir $olddir || true
}

sort-env-vars() {
    if [[ $(yq '.spec.template.spec.containers[].env // null' $1) != null ]]; then
        log-debug render "sorting containers env keys in manifest $1"
        yq -i '.spec.template.spec.containers[].env |= sort_by(.name)' $1
    fi
}

render-copy-files() {
    files_list="$karmah_dir"/files/*.yaml
    run-verbose-cmd cp -f ${files_list} ${manifest_dir}
}
