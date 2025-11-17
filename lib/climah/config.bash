
read_config() {
    : ${RENDER_CONFIG_FILE:=~/.config/karmah/config}
    if [[ -f ${RENDER_CONFIG_FILE} ]]; then
        source ${RENDER_CONFIG_FILE}
    fi
    if [[ -d config.d ]] && "${use_config_d:-true}"; then
        for inc in config.d/*.config; do
            source $inc
        done
    fi
    default_renderer=${RENDER_DEFAULT_RENDERER:-helm}
}
