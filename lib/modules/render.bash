
render::init-module() {
    add-module-help "actions to render manifests"
    local_vars+=" renderer output_dir already_rendered sort_env_vars"
    declare -g to_dir
    declare-action r render "render manifests to --to <path> (default tmp/manifests)"

    help_level=expert
    declare-action "" compare   "render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)"
    declare-action rm render-rm "remove all rendered manifests"

    add-func-option "" to       path  "other path to render to (default is tmp/manifests)"
    add-func-option "" with     path  used for comparison between two manifest trees
    add-flag-option "" tmp  "render to tmp/manifests (already default), do not commit"

}

option::to()        { to_dir="${2%%/}"; argparse_parse_count=2; }
option::with()      { with_dir="${2%%/}"; argparse_parse_count=2; }

action::render() {
    run-actions update
    log-info render "render with ${renderer} to ${output_dir}"
    run-verbose-cmd rm -rf ${output_dir}
    run-verbose-cmd mkdir -p ${output_dir}
    change-paths $output_dir
    for r in ${renderer//,/ }; do
        render-$r
    done
    already_rendered=true
}

action::render-rm() {
    log-info render "removing  ${target_name} manifests in ${output_dir}"
    run-verbose-cmd rm -rf ${output_dir}
}


action::compare() {
    olddir=${output_dir}
    local newdir=${with_dir:-deployed/manifests}/${target_name}
    log-info render "comparing ${target_name}: ${output_dir} with ${newdir}"
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
    run-verbose-cmd cp -f ${files_list} ${output_dir}
}
