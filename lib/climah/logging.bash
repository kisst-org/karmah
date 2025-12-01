
# This function is called before anything else, to immediately make logging work
init_logging() {
    declare -gi log_level_fatal=0
    declare -gi log_level_error=10
    declare -gi log_level_warn=20
    declare -gi log_level_info=30
    declare -gi log_level_verbose=40
    declare -gi log_level_debug=50
    declare -gi log_level=$log_level_info
    declare -g  log_cmds=false
    parse_loglevel "$@"
}

init_climah_module_logging() {
    add-option v verbose  ""    "give more output"
    add-option q quiet    ""    "show no output"
    add-option S show-script "" "show all commands without doing much"
    # TODO: parse multiple short options
    parse_arg_func[-vv]=parse-option-verbose2
    parse_arg_func[-vvv]=parse-option-verbose3

    add-flag-option C log-cmds  "show the commands being executed"
    add-flag-option n dry-run   "do not execute the actual commands"

    help_level=expert
    add-option "" debug   ""    show detailded debug info
}

# TODO -vv
parse-option-verbose()   { log_level+=10; }
parse-option-verbose2()  { log_level+=20; }
parse-option-verbose3()  { log_level+=30; }
parse-option-quiet()     { log_level=$log_level_warn; }
parse-option-debug()     { set -x; }
parse-option-show-script() {
    parse-option-quiet
    dry_run=true
    log_cmds=true
    parse-option-yes
}


log_is_error()   { (( ${log_level} >= ${log_level_error} )) }
log_is_warn()    { (( ${log_level} >= ${log_level_warn} )) }
log_is_info()    { (( ${log_level} >= ${log_level_info} )) }
log_is_verbose() { (( ${log_level:-30} >= ${log_level_verbose:-40} )) }
log_is_debug()   { (( ${log_level} >= ${log_level_debug} )) }

error()   { if $(log_is_error) ;   then printf "ERROR "; printf "%s " "${@}"; echo; fi }
warn()    { if $(log_is_warn) ;    then printf "WARN "; printf "%s " "${@}"; echo; fi }
info()    { if $(log_is_info) ;    then printf "# ";  printf "%s " "${@}"; echo; fi }
verbose() { if $(log_is_verbose) ; then printf "## "; printf "%s " "${@}"; echo; fi }
debug()   { if $(log_is_debug) ;   then printf "### ";  printf "%s " "${@}"; echo; fi }

verbose_cmd() {
    if (( $log_level >= $log_level_verbose )); then
        printf "    "; echo "${@}";
    elif $log_cmds; then
        printf "    "; echo "${@}";
    fi
    if ! ${dry_run:-false}; then
        cmd=$1; shift
        $cmd "${@}"
    fi
}

verbose_pipe() {
    pipe=$1
    shift
    if (( $log_level >= $log_level_verbose )); then
        printf "    "; echo "${@}" \| $pipe;
    elif $log_cmds; then
        printf "    "; echo "${@}" \| $pipe;
    fi
    if ! ${dry_run:-false}; then
        cmd=$1; shift
        $cmd "${@}" | $pipe
    fi
}


parse_loglevel() {
    for arg in "$@"; do
        if [[ $arg == -v ]]; then log_level+=10; fi
    done
}
