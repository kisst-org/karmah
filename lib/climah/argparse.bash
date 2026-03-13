
argparse-init-climah-vars() {
    declare -gA argparse_aliases=()
    declare -gA argparse_arg_func=()
    declare -gA argparse_arg_params=()
    declare -ga argparse_replaced_aliases=()   # remember for help function
    declare -ga argparse_original_args="${@}"  # remember for help function and others
    declare -g  argparse_extra_args=""
}

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

argparse-parse-arg() {
    local name=$1
    local func=${argparse_arg_func[$name]:-}
    if [[ ! -z $func ]]; then
        argparse_parse_count=1
        local argparse_params="${argparse_arg_params[$name]:-}"
        $func "$@"
    fi
}

argparse-parse-arguments() {
    declare -a argparse_to_parse=()            # after alias subsitution is done
    argparse-replace-aliases "${@}"
    set -- "${argparse_to_parse[@]}"
    log_level=$log_level_info
    while [[ $# > 0 ]]; do
        arg=$1
        shift
        argparse_parse_count=0
        argparse-parse-arg $arg "$@";
        if [[ "$argparse_parse_count" > 0 ]]; then
            shift $(( "$argparse_parse_count" - 1))
        elif [[ -f ${arg} ]]; then target_paths+=" ${arg}"
        elif [[ -d ${arg} ]]; then target_paths+=" ${arg%%/}" # remove a possible trailing /
        elif [[ $arg == "--" ]]; then break
        else
            argparse_extra_args+=" $arg"
        fi
    done
    argparse_extra_args+=" $*"
    argparse_extra_args=$(echo ${argparse_extra_args}) # trim spaces
    if [[ ! -z ${argparse_replaced_aliases:-} ]]; then # TODO: why is default needed, it should be declared anyway
        verbose COMMAND $(basename $0) ${argparse_to_parse[@]}
    fi
}

add-commas() { local args="${*// /,}"; echo ${args%%,}; }
add-spaces() { local args="${*//,/ }"; echo ${args%% }; }

argparse-show-aliases() {
  echo Aliases:
  for key in $(printf "%s\n" ${!argparse_aliases[@]} | sort); do
      printf "  %-14s %s\n" $key "${argparse_aliases[$key]}"
  done |sort -k2 -k1
}
