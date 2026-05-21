
split-yaml-docs-into-files() {
    # Cleans the stdin yaml to a normalized format
    # - pretty print with normalized indents
    # - sort all the keys
    # - remove comments
    # - apply a style with no quotes if not needed
    # Then it will split all documents in files named <kind>_<metadata.name>.yaml
    yq -P 'sort_keys(..)' | yq '... comments=""' | yq '.. style=""' | yq -s \"$manifest_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
    if ${sort_env_vars:-true}; then
        local f
        for f in ${manifest_dir}/*.yaml; do
            sort-env-vars $f
        done
    fi
    rm -f ${manifest_dir}/_.yaml
}

# TODO: This is slightly different form render split-yaml-docs-into-files
# because it is a yaml list, not separate yaml documents
split-yaml-items-into-files() {
    yq  '.items.[]' -s \"$manifest_dir/\"'+ (.kind | downcase) + "_" + .metadata.name + ".yaml"'
}
