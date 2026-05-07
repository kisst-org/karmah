
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

run-and-log-cmd() {
    local level=$1 logger=$2 cmd=$3 args
    local dry_run=$(get-option-value dry-run false)
    shift 3
    printf -v args " %s" "$@"
    log-at-level $level $logger "$cmd $args"
    if ! ${dry_run:-false}; then
        $cmd "$@"
    fi
}

run-verbose-cmd() {
    local maincmd=$1 cmd="$@"
    local dry_run=$(get-option-value dry-run false)
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
