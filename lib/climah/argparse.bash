
argparse-init-climah-vars() {
    declare -gA argparse_aliases=()
    declare -ga args_to_parse=()
    declare -gA arg_alias=()
    declare -gA parse_arg_func=()
}

argparse-replace-aliases() {
    for arg in "${@}"; do
        local al="${argparse_aliases[$arg]:-none}"
        if [[ "$al" != none ]]; then
            replaced=true
            args_to_parse+=($al)
        else
            args_to_parse+=("$arg")
        fi
    done
}

argparse-parse-arg() {
    local name=$1
    local func=${parse_arg_func[$name]:-}
    if [[ ! -z $func ]]; then
        parse_result=1
        $func "$@"
    fi
}

argparse-parse-arguments() {
    local replaced=false
    declare -g extra_args=""
    argparse-replace-aliases "${@}"
    set -- "${args_to_parse[@]}"
    log_level=$log_level_info
    while [[ $# > 0 ]]; do
        arg=${arg_alias[$1]:-$1}
        shift
        parse_result=0
        argparse-parse-arg $arg "$@";
        if [[ "$parse_result" > 0 ]]; then
            shift $(( "$parse_result" - 1))
        elif [[ -f ${arg} ]]; then target_paths+=" ${arg}"
        elif [[ -d ${arg} ]]; then target_paths+=" ${arg%%/}" # remove a possible trailing /
        elif [[ $arg == "--" ]]; then break
        else
            extra_args+=" $arg"
        fi
    done
    extra_args+=" $*"
    extra_args=$(echo ${extra_args})
    verbose COMMAND $(basename $0) ${args_to_parse[@]}
}

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

argparse-show-aliases() {
  echo Aliases:
  for key in $(printf "%s\n" ${!argparse_aliases[@]} | sort); do
      printf "  %-14s %s\n" $key "${argparse_aliases[$key]}"
  done |sort -k2 -k1
}
