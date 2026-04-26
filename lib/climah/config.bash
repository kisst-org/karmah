
read-config() {
    : ${RENDER_CONFIG_FILE:=~/.config/${climah_prog}/config}
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

config-pre-module-init() {
    if [[ -f config.d/.pre-init-modules ]]; then
        source config.d/.pre-init-modules
    fi
    if [[ -f .${climah_prog}.config ]]; then
        source .${climah_prog}.config
    fi
}
