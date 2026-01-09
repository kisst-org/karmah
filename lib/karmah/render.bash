
init_climah_module_render() {
    local_vars+=" renderer output_dir already_rendered"
    declare -g to_dir
    add-action r render update "render manifests to --to <path> (default tmp/manifests)"
    help_level=expert
    add-action "" compare   "render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)"
    add-action rm render-rm "remove all rendered manifests"
    set-pre-actions update        render
    set-pre-actions update,render compare

    add-option t to       path  "other path to render to (default is tmp/manifests)"
    add-option w with     path  used for comparison between two manifest trees
}

parse-option-to()        { to_dir="$2"; parse_result=2; }
parse-option-with()      { with_dir="$2"; parse_result=2; }


run-action-render() {
    info rendering ${target} with ${renderer} to ${output_dir}
    verbose_cmd rm -rf ${output_dir}
    verbose_cmd mkdir -p ${output_dir}
    for r in ${renderer//,/ }; do
        render_$r
    done
    already_rendered=true
}

run-action-render-rm() {
    info removing  ${target} manifests in ${output_dir}
    verbose_cmd rm -rf ${output_dir}
}


run-action-compare() {
    olddir=${output_dir}
    local newdir=${with_dir:-deployed/manifests}/${target}
    info comparing ${target}: ${output_dir} with ${newdir}
    verbose_cmd diff -r $newdir $olddir || true
}

split_into_files() {
    # Cleans the stdin yaml to a normalized format
    # - pretty print with normalized indents
    # - sort all the keys
    # - remove comments
    # - apply a style with no quotes if not needed
    # Then it will split all documents in files named <kind>_<metadata.name>.yaml
    yq -P 'sort_keys(..)' | yq '... comments=""' | yq '.. style=""' | yq -s \"$output_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
    rm -f ${output_dir}/_.yaml
}


render_copy-files() {
    files_list="$karmah_dir"/files/*.yaml
    verbose_cmd cp -f ${files_list} ${output_dir}
}
