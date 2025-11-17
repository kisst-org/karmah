
render_copy-files() {
    files_list="$karmah_dir"/files/*.yaml
    verbose_cmd cp -f ${files_list} ${output_dir}
}
