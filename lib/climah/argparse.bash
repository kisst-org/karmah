
init_climah_vars_argparse() {
    declare -gA aliases=()
    declare -ga parsed_args=()

    declare -g karmah_paths=""
    declare -g subdirs=""
    declare -ga updates=()
    declare -ga action_help=()
    declare -ga command_help=()
    declare -ga option_help=()

    declare -gA parse_arg_func=()
    declare -g action_list=""
    declare -g command
}

add_option() {
    local short=$1
    local name=$2
    local arg=$3
    shift 3
    local help=$@
    parse_arg_func[--$name]=parse_option_$name
    if [[ -z $short ]]; then
        name="--$name"
    else
        parse_arg_func[-$short]=parse_option_$name
        name="-$short|--$name"
    fi
    [[ -z $arg ]] || name+=" <$arg>"
    option_help+=("$(printf "  %-20s %s\n" "$name" "$help")")
}

parse_set_command() { command=run_command_$1; }
add_command() {
    local name=$1
    shift 1
    local help=$@
    parse_arg_func[$name]=parse_set_command
    command_help+=("$(printf "  %-13s %s\n" "$name" "$help")")
}

parse_append_action() { action_list+=$1;  }
parse_append_action_with_args() { action_list+=$1; collect_unknown_args=true; }
add_action() {
    local name=$1
    shift 1
    if [[ ${1:-} == --collect ]]; then
        shift
        parse_arg_func[$name]=parse_append_action_with_args
    else
        parse_arg_func[$name]=parse_append_action
    fi
    local help="$@"
    action_help+=("$(printf "  %-13s %s\n" "$name" "$help")")
}

parse_arg() {
    local name=$1
    local func=${parse_arg_func[$name]:-}
    if [[ ! -z $func ]]; then
        parse_result=1
        $func "$@"
    fi
}


replace_aliases() {
    for arg in "${@}"; do
        local al="${aliases[$arg]:-none}"
        if [[ "$al" != none ]]; then
            replaced=true
            parsed_args+=($al)
        else
            parsed_args+=("$arg")
        fi
    done
}

parse_options() {
    local replaced=false
    local collect_unknown_args=false
    declare -g extra_args=""
    replace_aliases "${@}"
    set -- "${parsed_args[@]}"
    log_level=$log_level_info
    while [[ $# > 0 ]]; do
        arg=$1
        parse_result=0
        parse_arg "$@";
        if [[ $arg = -vv ]]; then # TODO: parse multiple short options
            log_level+=20;
        elif [[ "$parse_result" > 0 ]]; then
            shift $(( "$parse_result" - 1))
        else
            if [[ -f ${arg} ]]; then karmah_paths+=" ${arg}"
            elif [[ -d ${arg} ]]; then karmah_paths+=" ${arg%%/}" # remove a trailing /
            elif $collect_unknown_args; then extra_args+=" $arg"
            else
                echo unknown argument ${arg}, should be an option, action or path
                show_short_help
                exit 1
            fi
        fi
        shift
    done
    verbose COMMAND $(basename $0) ${parsed_args[@]}
}
