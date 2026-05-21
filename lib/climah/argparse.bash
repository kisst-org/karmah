
argparse::declare-vars() {
    declare -gA argparse_aliases=()
    # parse-if-help-item is first to add any command to possible help
    declare -ga argparse_parse_funcs=(parse-if-help-item)
    declare -ga argparse_replaced_aliases=()   # remember for help function
    declare -gA argparse_short_map=()
    #declare -gA argparse_short_lookup=()
    declare -g argparse_original_args=""   # remember for help function and others
    declare -g  argparse_parsed_args=""
    declare -g  argparse_remaining_args=""
    declare -g  argparse_unknown_args=""
    declare -g  ignore_unknown_args=false
}

append-argparse-func()  { argparse_parse_funcs+=($1); }

add-argparse-alias() { add-alias "$@"; } # deprecated
add-alias() {
    local name=$1 expansion="${@:2}"
    argparse_aliases[$name]="$expansion";
    if [[ -z ${module:-} ]]; then
        module=argparse
    fi
    add-help-item "" $name alias:$name "" "alias for: $expansion"
}

argparse-parse-funcs() {
    for func in ${argparse_parse_funcs[@]}; do
        $func "$@"
        if [[ $argparse_parse_count > 0 ]]; then
            return
        fi
    done
}

argparse-parse-arguments() {
    argparse_original_args="${@}"
    while [[ $# > 0 ]]; do
        local alias="${argparse_aliases[$1]:-}"
        if [[ ! -z $alias ]]; then
            log-debug argparse "replacing alias $1 with \"$alias\""
            shift
            set - $alias "$@"
        fi
        arg=${argparse_short_map[$1]:-$1}
        shift
        local argparse_parse_count=0 argparse_understood_arg=false
        argparse-parse-funcs "$arg" "$@"
        if [[ "$argparse_parse_count" > 0 ]]; then
            argparse_parsed_args+=" $arg"
            shift $(( "$argparse_parse_count" - 1))
        elif [[ $arg == "--" ]]; then break
        else
            if ! $argparse_understood_arg; then
                argparse_unknown_args+=" $arg"
            fi
        fi
    done
    if [[ ! -z $argparse_unknown_args ]] && ! ${ignore_unknown_args}; then
        log-error argparse "unknown arguments: $argparse_unknown_args"
        if [[ $command_to_run == help ]]; then
            show-help
            exit 0
        else
            show-basic-help
            return 1
        fi
    fi
    argparse_remaining_args="$@"
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
}
argparse-add-short() {
    local short=$1 long=$2
    if [[ $long == ${argparse_short_map[$short]:-} ]]; then
        log-verbose argparse "WARN redefining short $short ==> $long"
    elif [[ ! -z ${argparse_short_map[$short]:-} ]]; then
        log-warn argparse "short $short ==> $long already defined to ${argparse_short_map[$short]}"
    #elif [[ ! -z ${argparse_short_lookup[$long]:-} ]]; then
        #log-warn argparse "short $short ==> $long clashes with existing short ${argparse_short_lookup[$long]}"
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
        #unset argparse_short_lookup[$long]
    fi
}
