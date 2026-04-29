
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
    declare -ga log_level_lookup=()
    local key; for key in ${!log_level_map[@]}; do
        local -i val=${log_level_map[$key]}
        log_level_lookup[$val]=$key
    done
    declare -gA logger_config=(
        [format]="LOG %s\n"
        [format.error]="ERROR %s\n"
        [format.warn]="WARN %s\n"
        [format.info]="# %s\n"
        [format.verbose]="## %s\n"
        [format.verbose.cmd]="    %s\n"
        [format.debug]="### %s\n"
        [format.trace]="#### %s\n"
        [appender]=log-to-console #log-to-console-with-timestamp
    )
    declare -gA logger_level=([root]=info)
}

loggers::init-module() {
    add-parse-option v  verbose  ""    "give more output"
    add-parse-option q  quiet    ""    "show no output"
    add-parse-option S  show-script "" "show all commands without doing much"
    add-flag-option  "" dry-run   "do not execute the actual commands"

    help_level=expert
    add-parse-option "" logger-level "logger level" "show all commands without doing much"

    # TODO: parse multiple short options
    argparse_parse_func_map[-vv]=parse-option-verbose2
    argparse_parse_func_map[-vvv]=parse-option-verbose3
}

increase-log-level() {
    local logger=$1
    local old_level=${logger_level[$logger]:-info}
    local -i value=${log_level_map[$old_level]}
    value+=10
    local new_level=${log_level_lookup[$value]:-trace}
    log-debug logger "increasing log-level for $logger from $old_level to $new_level"
    logger_level[$logger]=$new_level
}

parse-pre-init-loglevels() {
    for arg in "$@"; do
        case $arg in
            -v|--verbose) parse-option-verbose;;
            -vv)          parse-option-verbose2;;
            -vvv)         parse-option-verbose3;;
            -q|--quiet)   parse-option-quiet;;
        esac
    done
}

parse-option-verbose()   { increase-log-level root; }
parse-option-verbose2()  { increase-log-level root; increase-log-level root; }
parse-option-verbose3()  { increase-log-level root; increase-log-level root; increase-log-level root;}
parse-option-quiet()     { log_level=$log_level_warn; logger_level[root]=warn; }
parse-option-logger-level() {
    local logger=$2 level=$3 # TODO check number of args
    log-debug logger "setting log-level for $logger to $level"
    logger_level[$logger]=$level
    argparse_parse_count=3
}
find-logger-level()  {
    local logger=$1
    local result=${logger_level[root]}
    local path=""
    for part in ${logger//./ }; do
        path="$path.$part"
        result="${logger_level[${path#.}]:-$result}"
        if [[ $path == .sub* ]]; then
            echo XXX path=$path result=$result >/dev/stderr
        fi
    done
    echo "$result"
}

find-logger-config() {
    local type=$1 logger=$2
    local path=$type
    local result="${logger_config[$path]}";
    for part in ${logger//./ }; do
        path="$path.$part"
        result="${logger_config[$path]:-$result}"
    done
    echo "$result"
}

logger-shows-level() {
    local logger=$1 level=$2
    local lvl=$(find-logger-level $logger)
    (( ${log_level_map[$lvl]} >= ${log_level_map[$level]} ))
}

##########################
# logging functions

log-to-console() {
    local level=$1 logger=$2 message="$3"
    local format="$(find-logger-config format $level.$logger)"
    printf "$format" "$message"
}
log-to-console-with-timestamp() {
    local level=$1 logger=$2 message="$3"
    local format="$(find-logger-config format $level.$logger)"
    printf "%s $format" ":$(date -I)" "$message"
}


log-at-level() {
    local level=$1 logger=$2 message="$3"
    if $(logger-shows-level $logger $level); then
        local appender="$(find-logger-config appender $level.$logger)"
        $appender $level $logger "$message"
    fi
}
log-error()   { log-at-level error $1 "$2"; }
log-warn()    { log-at-level warn $1 "$2"; }
log-info()    { log-at-level info $1 "$2"; }
log-verbose() { log-at-level verbose $1 "$2"; }
log-debug()   { log-at-level debug $1 "$2"; }
log-trace()   { log-at-level trace $1 "$2"; }

##########################
# logging commands to be run
parse-option-show-script() {
    parse-option-quiet
    logger_level[cmd]=verbose
    dry_run=true
    parse-option-yes
}

run-and-log-cmd() {
    local level=$1 logger=$2 cmd=$3 args
    shift 3
    printf -v args " %s" "$@"
    log-at-level $level $logger "$cmd $args"
    if ! ${dry_run:-false}; then
        $cmd "$@"
    fi
}

run-verbose-cmd() {
    local maincmd=$1 cmd="$@"
    log-at-level verbose cmd.$maincmd "${*}"
    if ! ${dry_run:-false}; then
        pipe=${cmd/*|/}
        cmd=${cmd/|*/}
        if [[ "$pipe" == "$cmd" ]]; then
            $cmd
        else
            $cmd | $pipe
        fi
    fi
}
