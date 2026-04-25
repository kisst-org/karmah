
render::init-climah-module() {
    add-module-help "actions to render manifests"
    local_vars+=" renderer output_dir already_rendered sort_env_vars"
    declare -g to_dir
    add-karmah-action r render update "render manifests to --to <path> (default tmp/manifests)"
    set-action-pre-flow load-karmah,update render

    help_level=expert
    add-render-action "" compare   "render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)"
    add-render-action rm render-rm "remove all rendered manifests"

    add-parse-option "" to       path  "other path to render to (default is tmp/manifests)"
    add-parse-option "" with     path  used for comparison between two manifest trees
    add-flag-option "" tmp  "render to tmp/manifests (already default), do not commit"

}

parse-option-to()        { to_dir="${2%%/}"; argparse_parse_count=2; }
parse-option-with()      { with_dir="${2%%/}"; argparse_parse_count=2; }

add-render-action() {
    add-action "${@}"
    set-action-pre-flow load-karmah,update,render "$2"
}


run-action-render() {
    log-info render "rendering ${target_name} with ${renderer} to ${output_dir}"
    error-if-action-args
    verbose-cmd rm -rf ${output_dir}
    verbose-cmd mkdir -p ${output_dir}
    for r in ${renderer//,/ }; do
        render-$r
    done
    already_rendered=true
}

run-action-render-rm() {
    log-info render "removing  ${target_name} manifests in ${output_dir}"
    warn-if-action-args
    verbose-cmd rm -rf ${output_dir}
}


run-action-compare() {
    olddir=${output_dir}
    local newdir=${with_dir:-deployed/manifests}/${target_name}
    log-info render "comparing ${target_name}: ${output_dir} with ${newdir}"
    verbose-cmd diff -r $newdir $olddir || true
}

sort-env-vars() {
    if [[ $(yq '.spec.template.spec.containers[].env // null' $1) != null ]]; then
        debug sorting containers env keys in manifest $1
        yq -i '.spec.template.spec.containers[].env |= sort_by(.name)' $1
    fi
}

render-copy-files() {
    files_list="$karmah_dir"/files/*.yaml
    verbose-cmd cp -f ${files_list} ${output_dir}
}
