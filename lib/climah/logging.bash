
# This function is called before anything else, to immediately make logging work
init-logging() {
    declare -gi log_level_fatal=0
    declare -gi log_level_error=10
    declare -gi log_level_warn=20
    declare -gi log_level_info=30
    declare -gi log_level_verbose=40
    declare -gi log_level_debug=50
    declare -gi log_level=$log_level_info
    declare -g  log_cmds=false
    parse-loglevel "$@"
}

logging::init-module() {
    add-flag-option C  log-cmds  "show the commands being executed"
    help_level=expert
    add-parse-option "" debug        ""    show detailed debug info
    add-flag-option  "" debug-init   ""    show detailed debug info during init phase
}
parse-option-debug()     { set -x; }


log-is-error()   { (( ${log_level} >= ${log_level_error} )) }
log-is-warn()    { (( ${log_level} >= ${log_level_warn} )) }
log-is-info()    { (( ${log_level} >= ${log_level_info} )) }
log-is-verbose() { (( ${log_level} >= ${log_level_verbose} )) }
log-is-debug()   { (( ${log_level} >= ${log_level_debug} )) }

error()   { if $(log-is-error);   then printf "*ERROR %s \n" "${*}";  fi }
warn()    { if $(log-is-warn);    then printf "*WARN %s \n" "${*}";  fi }
info()    { if $(log-is-info);    then printf "* %s \n" "${*}";  fi }
verbose() { if $(log-is-verbose); then printf "*# %s \n" "${*}";  fi }
debug()   { if $(log-is-debug);   then printf "*## %s \n" "${*}";  fi }

error-stderr()   { if $(log-is-error);   then printf >/dev/stderr "ERROR %s \n" "${*}";  fi }
warn-stderr()    { if $(log-is-warn);    then printf >/dev/stderr "WARN %s \n" "${*}";  fi }
info-stderr()    { if $(log-is-info);    then printf >/dev/stderr "# %s \n" "${*}";  fi }
verbose-stderr() { if $(log-is-verbose); then printf >/dev/stderr "## %s \n" "${*}";  fi }
debug-stderr()   { if $(log-is-debug);   then printf >/dev/stderr "### %s \n" "${*}";  fi }


verbose-cmd() {
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

verbose-pipe() {
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


parse-loglevel() {
    for arg in "$@"; do
        if [[ $arg == --debug-init ]];   then log_level+=20; fi
    done
}
