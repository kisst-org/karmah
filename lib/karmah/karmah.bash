# karmah: do stuff based on *.karmah file
karmah-main() {
    declare -g karmah_var_list=""
    # too many actions and options so only show some basic stuff
    default_module_help_level=expert
    basic_help_modules="loggers actions options commands"
    climah-init "$@"
    climah_prog=karmah
    append-argparse-func parse-if-target
    climah-parse-args "$@"
    climah-run
}


karmah::declare-vars() {
    declare -g local_vars="karmah_type target_name disable_target"
    declare -g default_karmah_type
}

karmah::init-module() {
    add-command "" version ""  "show version of karmah"
    help_level=expert
    add-command run run-karmah-actions "" "run one or more actions for all targets (default command)"
    climah_prog=karmah
    default_action=render
    declare-action "" init-karmah "load *.karmah init file(s) and run ::init-karmah function"
    declare-action "" clear-karmah "clear all karmah-vars"
    add-karmah-var "" karmah_type "<name>" "override any karmah_type declared in karmah files and init-karmah"
    log-verbose karmah "default_karmah_type=${default_karmah_type:-base}"
    default_command=run-karmah-actions
    add-value-option "" only-if     func "run target only if a function returns true"
    add-value-option "" skip-if     func "skip target if a function returns true"
}

command::version() { echo karmah version: $karmah_version; }
command::run-karmah-actions() { run-func-for-targets run-karmah-actions; }
run-karmah-actions() {
    declare -A action_already_run=()
    if [[ -e $target_path ]]; then
        local a; for a in $action_list; do
            local v; for v in ${action_karmah_vars[$a]}; do
                local $v
            done
        done
        run-actions init-karmah
        local current_klass=${karmah_klass:-$karmah_type}
        local func=$(get-option-value skip-if)
        if [[ ! -z $func ]]; then
            if $($func); then
                log-info karmah "skipping $target_path because $func returned true"
                run-actions clear-karmah
                return
            fi
        fi
        local onlyfunc=$(get-option-value only-if)
        if [[ ! -z $onlyfunc ]]; then
            if ! $($onlyfunc); then
                log-info karmah "skipping $target_path because $onlyfunc returned false"
                run-actions clear-karmah
                return
            fi
        fi
        run-actions "$action_list,clear-karmah"
    else
        log-info karmah "skipping non existing path $target_path"
    fi
}

init-parent-karmah() {
    local typ=$1
    log-verbose karmah "calling ${typ}::init-karmah"
    if $(function-exists $typ::init-klass); then
        current_klass=$typ $typ::init-klass
    else
        $typ::init-karmah # for backward compatibility
    fi
}

base::init-karmah() { log-verbose karmah "using base karmah_type initializer"; }

action::init-karmah() {
    if [[ -f $target_path ]]; then
        karmah_file=$target_path
    elif [[ -d ${target_path:-} ]]; then
        karmah_file=($target_path/*.karmah) # use array for globbing
    fi
    if [[ ! -f ${karmah_file:-} ]]; then
        log-info karmah "skipping $target_path"
        # TODO: warn, error or skip
        return 0
    fi
    load-karmah-file
    if ${disable_target:-false}; then
        abort_actions=true
        log-info actions "skipping $target_path, because disable_target is set to true"
        return
    fi
    log-verbose karmah "calling ${karmah_type}::init-karmah"
    ${karmah_type}::init-karmah
}
action::clear-karmah() {
    local vars_to_clear="${used_karmah_vars:-} ${local_vars:-}"
    log-debug karmah "clearing karmah-vars: ${vars_to_clear}"
    unset ${vars_to_clear}
}


load-karmah-file() {
    declare -g karmah_type
    if [[ ! -f "${karmah_file}" ]]; then
        log-info karmah "skipping $karmah_file"
        return
    fi
    # cleanup of any vars that might have been set with previous file
    log-trace karmah "clearing $local_vars"
    unset $local_vars
    declare -g $local_vars

    karmah_dir=$(dirname $karmah_file)
    common_dir=$(dirname $karmah_dir)/common
    log-verbose karmah "loading $karmah_file"
    source ${karmah_file}
    common-karmah
    use-karmah-var karmah_type
}

common-karmah() {
    local force_karmah_type=$(get-option-value force-karmah-type) # TODO karmah_var will do this
    use-paths ${karmah_dir}
    local common_karmah_file=($common_dir/common*.karmah)
    if [[ -f $common_karmah_file ]]; then
        log-verbose karmah "loading $common_karmah_file"
        source $common_karmah_file
        use-paths $common_karmah_file
    fi
}
