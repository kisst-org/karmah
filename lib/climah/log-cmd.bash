
log-cmd::init-module() {
    add-func-option S simulate "" "show all commands without doing much"
    add-flag-option D dry-run     "do not execute the actual commands"
}

option::simulate() {
    option::quiet
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
    log-at-level verbose $logger "${*}"
    if ! ${dry_run:-false}; then
        pipe=${cmd/*|/}
        cmd=${cmd/|*/}
        cmd_exit_code=0
        if ${ignore_cmd_exit_code:-false}; then
            $cmd || cmd_exit_code=$?
            ignore_cmd_exit_code=false
        elif [[ "$pipe" == "$cmd" ]]; then
            $cmd
        else
            $cmd | $pipe
        fi
    fi
}
