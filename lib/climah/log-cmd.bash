
log-cmd::init-module() {
    add-func-option S show-script "" "show script of commands that would be executed"
    add-flag-option D dry-run        "do not execute the actual commands"
    add-flag-option C check          "check-mode only run commands that will not change anything"
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
    local do_run=true
    local prefix=""
    if $(get-option-value dry-run false); then
        do_run=false
    elif $(get-option-value check false); then
        if ${run_in_check_mode:-false}; then
            run_in_check_mode=false # reset so every call needs to set explicitely
            do_run=true
        else
            prefix="# "  # prefix to show it is not really run
            do_run=false
        fi
    fi
    local logmsg
    printf -v logmsg "%q " "$@"
    log-at-level verbose $logger "$prefix$logmsg"
    cmd_exit_code=0
    if ${do_run}; then
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
