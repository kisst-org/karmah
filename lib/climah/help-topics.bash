
help-topics::init-module() {
    add-help-topic al  aliases "show all defined aliases"
    add-help-topic top topics  "show all help-topics"
}

add-help-topic() {
    # TODO: func is not needed anymore
    local short=$1 name=$2 summary=${3:-no summary}
    log-trace help "adding help-topic: ${@}"
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    add-help-item $name topic:$name "" "$summary"
}

show-help-about-topic() {
    local ignore=$1 type=$2
    if $(function-exists show-help-about-topic-$type); then
        show-help-about-topic-$type
    else
        help_show_level=all
        show-help-section $type
    fi
}

show-help-section() {
    local type=$1 header=${2:-}
    if $(has-help-items $type); then
        echo "${header:-${type}s:}"
        list-help-items $type
        echo
    fi
}


show-help-about-topic-topics() {
    help_show_level=all
    cat <<EOF
${climah_prog_name} help [<topic>]

topic can be any of:
EOF
    list-help-items topic
}
