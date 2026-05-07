
help-topics::init-module() {
    add-help-topic ""  alias "show all defined aliases"
    add-help-topic top topic "show all help-topics"
}

add-help-topic() {
    # TODO: func is not needed anymore
    local short=$1 name=$2 summary=${3:-no summary}
    log-trace help "adding help-topic: ${@}"
    if [[ ! -z $short ]]; then argparse-add-short $short $name; fi
    add-help-item $name topic:$name "" "$summary"
}

show-help-about-topic() {
    local name=$(help-item-name $1)
    if $(function-exists show-help-about-topic-$name); then
        show-help-about-topic-$name
    else
        local plural=${name}s
        if [[ $name == alias ]]; then plural=aliases; fi
        help_show_level=all
        echo "All available ${plural}"
        list-help-items all::$name
    fi
}

show-help-section() {
    local topic=$1 header=${2:-}
    if $(has-help-items $topic); then
        echo "${header:-$(help-item-type $topic)s:}"
        list-help-items $topic
        echo
    fi
}
