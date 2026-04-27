
argparse::declare-vars() {
    declare -gA argparse_aliases=()
    declare -gA argparse_parse_func_map=()
    declare -ga argparse_parse_funcs=(argparse-parse-arg)
    declare -gA argparse_parse_params=()
    declare -ga argparse_replaced_aliases=()   # remember for help function
    declare -gA argparse_short_map=()
    declare -gA argparse_short_lookup=()
    declare -g argparse_original_args=""   # remember for help function and others
    declare -g  argparse_parsed_args=""
    declare -g  argparse_extra_args=""
    declare -g  argparse_unknown_args=""
}

append-argparse-func()  { argparse_parse_funcs+=($1); }
prepend-argparse-func() { argparse_parse_funcs=($1 $argparse_parse_funcs   ); }

add-argparse-alias() { argparse_aliases[$1]="$2"; }

argparse-replace-aliases() {
    for arg in "${@}"; do
        local al="${argparse_aliases[$arg]:-none}"
        if [[ "$al" != none ]]; then
            argparse_replaced_aliases+=($al)
            argparse_to_parse+=($al)
        else
            argparse_to_parse+=("$arg")
        fi
    done
}

argparse-parse-funcs() {
    for func in ${argparse_parse_funcs[@]}; do
        $func "$@"
        if [[ $argparse_parse_count > 0 ]]; then
            return
        fi
    done
}

argparse-parse-arg() {
    local name=$1
    local func=${argparse_parse_func_map[$name]:-}
    if [[ ! -z $func ]]; then
        argparse_parse_count=1
        local argparse_param_list=("${argparse_parse_params[$name]:-}")
        $func "$@"
    fi
}


argparse-parse-arguments() {
    argparse_original_args="${@}"
    declare -a argparse_to_parse=()            # after alias subsitution is done
    argparse-replace-aliases "${@}"
    set -- "${argparse_to_parse[@]}"
    log_level=$log_level_info
    while [[ $# > 0 ]]; do
        arg=${argparse_short_map[$1]:-$1}
        shift
        local argparse_parse_count=0 argparse_understood_arg=false
        argparse-parse-funcs "$arg" "$@"
        if [[ "$argparse_parse_count" > 0 ]]; then
            argparse_parsed_args+=" $arg"
            shift $(( "$argparse_parse_count" - 1))
        elif [[ -f ${arg} ]]; then target_paths+=" ${arg}"
        elif [[ -d ${arg} ]]; then target_paths+=" ${arg%/}" # remove a possible trailing /
        elif [[ $arg == "--" ]]; then break
        else
            if ! $argparse_understood_arg; then
                argparse_unknown_args+=" $arg"
            fi
        fi
    done
    if [[ ! -z $argparse_unknown_args ]]; then
        log-error argparse "unknown arguments: $argparse_unknown_args"
        if [[ $command_to_run == help ]]; then
            show-help
            exit 0
        else
            show-basic-help
            return 1
        fi
    fi
    argparse_extra_args+=" $*"
    argparse_extra_args=$(echo ${argparse_extra_args}) # trim spaces
    if [[ ! -z ${argparse_replaced_aliases:-} ]]; then # TODO: why is default needed, it should be declared anyway
        log-verbose argparse "COMMAND $(basename $0) ${argparse_to_parse[@]}"
    fi
}

argparse-show-aliases() {
  echo Aliases:
  for key in $(printf "%s\n" ${!argparse_aliases[@]} | sort); do
      printf "  %-14s %s\n" $key "${argparse_aliases[$key]}"
  done |sort -k2 -k1
}

argparse-redefine-short() {
    local short=$1 long=$2
    argparse_short_map[$short]=$long
    argparse_short_lookup[$long]=$short
}
argparse-add-short() {
    local short=$1 long=$2
    if [[ $long == ${argparse_short_map[$short]:-} ]]; then
        log-verbose argparse "WARN redefining short $short ==> $long"
    elif [[ ! -z ${argparse_short_map[$short]:-} ]]; then
        log-warn argparse "short $short ==> $long already defined to ${argparse_short_map[$short]}"
    elif [[ ! -z ${argparse_short_lookup[$long]:-} ]]; then
        log-warn argparse "short $short ==> $long clashes with existing short ${argparse_short_lookup[$long]}"
    fi
    argparse-redefine-short $short $long
}
argparse-clear-short() {
    local short=$1
    local long=${argparse_short_map[$short]:-}
    if [[ -z $long ]]; then
        log-warn argparse "attempting to clearing unset short $short"
    else
        unset argparse_short_map[$short]
        unset argparse_short_lookup[$long]
    fi
}
