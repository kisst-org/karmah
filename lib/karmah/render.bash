
init_climah_module_render() {
    add_action render "render manifests to --to <path> (default tmp/manifests)"
    add-flow-command "" render update,render
    global_vars+=" renderer output_dir already_rendered"
    declare -g to_dir
    help_level=expert
    add_option s subdir   dir   "add subdir to list of subdirs (can be comma separated list)"
    add_option t to       path  "other path to render to (default is tmp/manifests)"
    add_option w with     path  used for comparison between two manifest trees
    add_action compare "render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)"
}

parse_option_subdir()    { subdirs+=" $2"; parse_result=2; }
parse_option_to()        { to_dir="$2"; parse_result=2; }
parse_option_with()      { with_dir="$2"; parse_result=2; }

render_manifests() {
    if  ${already_rendered:-false}; then
        debug allready rendered manifests
    else
        already_rendered=true
        run_action_render
    fi
}

run_action_render() {
    run_action_update
    info rendering ${target} with ${renderer} to ${output_dir}
    verbose_cmd rm -rf ${output_dir}
    verbose_cmd mkdir -p ${output_dir}
    for r in ${renderer//,/ }; do
        render_$r
    done
    already_rendered=true
}

run_action_render-rm() {
    run_action_update
    info removing  ${target} manifests in ${output_dir}
    verbose_cmd rm -rf ${output_dir}
}


run_action_compare() {
    run_action_render
    olddir=${output_dir}
    local newdir=${with_dir:-deployed/manifests}/${target}
    info comparing ${target}: ${output_dir} with ${newdir}
    verbose_cmd diff -r $newdir $olddir || true
}

split_into_files() {
    yq -P 'sort_keys(..)' | yq -s \"$output_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
    rm -f ${output_dir}/_.yaml
}
