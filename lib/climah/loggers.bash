
# This function is called before anything else, to immediately make logging work
init-loggers() {
    declare -gA log_level_map=(
      [fatal]=0
      [error]=10
      [warn]=20
      [info]=30
      [verbose]=40
      [debug]=50
      [trace]=60
    )
    declare -gA logger_config=(
        [format.error]="ERROR %s\n"
        [format.warn]="WARN %s\n"
        [format.info]="# %s\n"
        [format.verbose]="## %s\n"
        [format.debug]="### %s\n"
    )
    declare -gA logger_level=([root]=info)
}

loggers::init-climah-module() {
    add-parse-option v  verbose  ""    "give more output"
    add-parse-option "" quiet    ""    "show no output"
    add-parse-option S  show-script "" "show all commands without doing much"

    add-flag-option "" dry-run   "do not execute the actual commands"

    # TODO: parse multiple short options
    argparse_parse_func_map[-vv]=parse-option-verbose2
    argparse_parse_func_map[-vvv]=parse-option-verbose3
}

parse-option-verbose()   { log_level+=10; logger_level[root]=verbose; }
parse-option-verbose2()  { log_level+=20; logger_level[root]=debug; }
parse-option-verbose3()  { log_level+=30; logger_level[root]=trace; }
parse-option-quiet()     { log_level=$log_level_warn; logger_level[root]=warn; }

find-logger-level()  { echo ${logger_level[$1]:-${logger_level[root]}}; } # TODO do real search
find-logger-config() { echo ${logger_config[$1]}; } # TODO do real search

logger-shows-level() {
    local logger=$1 level=$2
    local lvl=$(find-logger-level $logger)
    (( ${log_level_map[$lvl]} >= ${log_level_map[$level]} ))
}

##########################
# logging functions

log-at-level() {
    local level=$1 logger=$2 message="$3"
    if $(logger-shows-level $logger $level); then
        local format="$(find-logger-config "format.$level")" # TODO add.$logger")
        printf "$format" "$message"
    fi
}
log-error()   { log-at-level error $1 "$2"; }
log-warn()    { log-at-level warn $1 "$2"; }
log-info()    { log-at-level info $1 "$2"; }
log-verbose() { log-at-level verbose $1 "$2"; }
log-debug()   { log-at-level debug $1 "$2"; }

##########################
# logging commands to be run
parse-option-show-script() {
    parse-option-quiet
    dry_run=true
    log_cmds=true
    parse-option-yes
}

run-and-log-cmd() {
    local level=$1 logger=$2 cmd=$3 args
    shift 3
    printf -v args "%qs " "$@"
    log-at-level $level $logger "$cmd $args"
    if ! ${dry_run:-false}; then
        cmd=$1; shift
        $cmd $args
    fi
}

run-and-log-pipe() {
    : #TODO
}
