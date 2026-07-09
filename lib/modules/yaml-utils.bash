
yaml::init-module() {
    add-module-summary "commands to work with yaml"
    add-command  ym   yaml-merge           "" "yaml stdin yaml documents into 1 yaml doc"
    add-command  ysk  yaml-sort-keys       "" "sort yaml keys on all levels from stdin"
    add-command  ysm  yaml-split-manifests "" "split yaml kubernetes manifests in separate-files "
}

command::yaml-merge() { yq eval-all '. as $item ireduce ({}; . * $item)' | yq -P 'sort_keys(..)'; }
command::yaml-sort-keys()  { yq -P 'sort-keys(..)'; }
command::yaml-split-manifests() {
    local to=$(get-option-value to tmp)
    yq -s \"$to/\"' + (.kind | downcase) + "_" + .metadata.name + ".yaml"'
}

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
