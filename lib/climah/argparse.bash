
init_climah_vars_argparse() {
    declare -gA aliases=()
    declare -ga args_to_parse=()
    declare -gA arg_alias=()
    declare -gA parse_arg_func=()
    declare -gA collect_remaining_after=()
    declare -gA collect_unknown_after=()
}

replace_aliases() {
    for arg in "${@}"; do
        local al="${aliases[$arg]:-none}"
        if [[ "$al" != none ]]; then
            replaced=true
            args_to_parse+=($al)
        else
            args_to_parse+=("$arg")
        fi
    done
}

parse_arg() {
    local name=$1
    local func=${parse_arg_func[$name]:-}
    if [[ ! -z $func ]]; then
        parse_result=1
        $func "$@"
    fi
}

parse-arguments() {
    local replaced=false
    local collect_unknown_args=false
    declare -g extra_args=""
    replace_aliases "${@}"
    set -- "${args_to_parse[@]}"
    parse_arg_func[--]=collect-remaining-arguments
    log_level=$log_level_info
    while [[ $# > 0 ]]; do
        arg=${arg_alias[$1]:-$1}
        shift
        parse_result=0
        parse_arg $arg "$@";
        if [[ "$parse_result" > 0 ]]; then
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
        if ${collect_unknown_after[$arg]:-false};   then collect-unknown-arguments;   fi
        if ${collect_remaining_after[$arg]:-false}; then collect-remaining-arguments; fi
        if ${collect_remaining_args:-false}; then break; fi
    done
    extra_args+=" $*"
    extra_args=${extra_args%% }
    verbose COMMAND $(basename $0) ${args_to_parse[@]}
}

collect-unknown-after()   {
    local a
    for a in "${@//,/ }"; do
        collect_unknown_after[$a]=true;
    done
}
collect-remaining-after()   {
    local a
    for a in "${@//,/ }"; do
        collect_remaining_after[$a]=true;
    done
}

collect-unknown-arguments()   { collect_unknown_args=true; }
collect-remaining-arguments() { collect_remaining_args=true; }

add-commas() {
    local args="$*"
    args=${args// /,}
    echo ${args%%,}
}

add-spaces() {
    local args="$*"
    args=${args//,/ }
    echo ${args%% }
}
