
log-cmd::init-module() {
    add-func-option S show-script "" "show script of commands that would be executed"
    add-flag-option D dry-run        "do not execute the actual commands"
}

option::show-script() {
    logger_config[level:cmd]=verbose
    set-option-value dry-run true
    option::yes
}

run-verbose-cmd() {
    local maincmd=$1 cmd="$@"
    local logger=cmd.$maincmd
    if [[ ! -z ${module:-} ]]; then
        logger+=".${module}"
    fi
    local dry_run=$(get-option-value dry-run false)
    local logmsg
    printf -v logmsg "%q " "$@"
    log-at-level verbose $logger "$logmsg"
    cmd_exit_code=0
    if ! ${dry_run:-false}; then
        pipe=${cmd/*|/}
        cmd=${cmd/|*/}
        if ${ignore_cmd_exit_code:-false}; then
            $cmd || cmd_exit_code=$?
            ignore_cmd_exit_code=false
        elif [[ "$pipe" == "$cmd" ]]; then
            "$@"
        else
            # TODO: if cmd/pipe had arguments with spaces, this will not work
            $cmd | $pipe
        fi
    fi
}
