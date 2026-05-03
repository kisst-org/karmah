
help-topics::init-module() {
    add-help-topic al  aliases  argparse-show-aliases "show all defined aliases"
    add-help-topic top topic    show-help-topics "show all help-topics"
}

add-help-topic() {
    # TODO: func is not needed anymore
    local short=$1 name=$2 func=${3} summary=${4:-no summary}
    log-trace help "adding help-topic: ${@}"
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    add-help-item $name topic:$name "" "$summary"
}

show-help-about-topic() {
    local ignore=$1 type=$2
    help_show_level=all
    show-help-section $type
}

show-help-section() {
    local type=$1 header=${2:-}
    if $(has-help-items $type); then
        echo "${header:-${type}s:}"
        list-help-items $type
        echo
    fi
}


show-help-topics() {
cat <<EOF
${climah_prog_name} help [<topic>]

topic can be any of:
EOF
    list-help-items topic
}
