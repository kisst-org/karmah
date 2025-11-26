
# This function is called before anything else, to immediately make logging work
init_logging() {
    declare -gi log_level_fatal=0
    declare -gi log_level_error=10
    declare -gi log_level_warn=20
    declare -gi log_level_info=30
    declare -gi log_level_verbose=40
    declare -gi log_level_debug=50
    declare -gi log_level=$log_level_info
    declare -g  log_commands=false
    parse_loglevel "$@"
}

init_climah_module_logging() {
    add_option v verbose  ""    give more output
    add_option C show-cmd ""    show the commands being executed
    add_option q quiet    ""    show no output
    add_option n dry-run  ""    do not execute the actual commands
    help_level=expert
    add_option "" debug   ""    show detailded debug info
}

# TODO -vv
parse_option_verbose()   { log_level+=10; }
parse_option_quiet()     { log_level=$log_level_warn; }
parse_option_show-cmd()  { log_commands=true; }
parse_option_dry-run()   { dry_run=true; }
parse_option_debug()     { set -x; }


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
    elif $log_commands; then
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
    elif $log_commands; then
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
