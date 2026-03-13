
render-init-climah-module() {
    local_vars+=" renderer output_dir already_rendered sort_env_vars"
    declare -g to_dir
    add-karmah-action r render update "render manifests to --to <path> (default tmp/manifests)"
    help_level=expert
    add-karmah-action "" compare   "render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)"
    add-karmah-action rm render-rm "remove all rendered manifests"
    set-pre-actions update        render
    set-pre-actions update,render compare

    options-add t to       path  "other path to render to (default is tmp/manifests)"
    options-add w with     path  used for comparison between two manifest trees
}

parse-option-to()        { to_dir="$2"; argparse_parse_count=2; }
parse-option-with()      { with_dir="$2"; argparse_parse_count=2; }


run-action-render() {
    info rendering ${target_name} with ${renderer} to ${output_dir}
    error-if-action-args
    verbose-cmd rm -rf ${output_dir}
    verbose-cmd mkdir -p ${output_dir}
    for r in ${renderer//,/ }; do
        render-$r
    done
    already_rendered=true
}

run-action-render-rm() {
    info removing  ${target_name} manifests in ${output_dir}
    warn-if-action-args
    verbose-cmd rm -rf ${output_dir}
}


run-action-compare() {
    olddir=${output_dir}
    local newdir=${with_dir:-deployed/manifests}/${target_name}
    info comparing ${target_name}: ${output_dir} with ${newdir}
    verbose-cmd diff -r $newdir $olddir || true
}

sort-env-vars() {
    if [[ $(yq '.spec.template.spec.containers[].env // null' $1) != null ]]; then
        debug sorting containers env keys in manifest $1
        yq -i '.spec.template.spec.containers[].env |= sort_by(.name)' $1
    fi
}

split-into-files() {
    # Cleans the stdin yaml to a normalized format
    # - pretty print with normalized indents
    # - sort all the keys
    # - remove comments
    # - apply a style with no quotes if not needed
    # Then it will split all documents in files named <kind>_<metadata.name>.yaml
    yq -P 'sort_keys(..)' | yq '... comments=""' | yq '.. style=""' | yq -s \"$output_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
    if ${sort_env_vars:-true}; then
        local f
        for f in ${output_dir}/*.yaml; do
            sort-env-vars $f
        done
    fi
    rm -f ${output_dir}/_.yaml
}

render-copy-files() {
    files_list="$karmah_dir"/files/*.yaml
    verbose-cmd cp -f ${files_list} ${output_dir}
}
