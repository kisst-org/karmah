
render_kustomize() {
    local command="kubectl kustomize --enable-helm"
    #used_files+=" $helm_chart_dir/$ch"
    verbose_pipe split_into_files "$command ${karmah_dir}"
}
