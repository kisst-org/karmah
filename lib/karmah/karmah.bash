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
    declare -g local_vars=""
    declare -g default_karmah_type
}

karmah::init-module() {
    add-module-summary "mechanism to set vars per target to be used by actions"
    add-command "" version ""  "show version of karmah"
    help_level=expert
    add-command run run-karmah-actions "" "run one or more actions for all targets (default command)"
    climah_prog=karmah
    default_action=render
    add-karmah-var "" karmah_type name "define the karmah_type to define extra vars"
    add-karmah-var "" disable_target bool  "flag to signal that the target should be skipped"
    declare-action "" init-karmah "load *.karmah init file(s) and run ::init-karmah function" \
        set-vars:karmah_type,disable_target:=false
    log-verbose karmah "default_karmah_type=${default_karmah_type:-base}"
    default_command=run-karmah-actions
    add-value-option "" only-if     func "run target only if a function returns true"
    add-value-option "" skip-if     func "skip target if a function returns true"
    add-help-topic karvar karmah-var "show all karmah-vars"
}

command::version() { echo karmah version: $karmah_version; }
command::run-karmah-actions() { run-func-for-targets run-karmah-actions; }
run-karmah-actions() {
    declare -A action_already_run=()
    if [[ -e $target_path ]]; then
        log-trace karmah.var "clearing karmah-vars $karmah_var_list $local_vars"
        local $karmah_var_list $local_vars # TODO remove local vars
        run-actions init-karmah
        local current_klass=${karmah_klass:-$karmah_type}
        log-verbose karmah "calling ${karmah_type}::init-karmah"
        ${karmah_type}::init-karmah
        local func=$(get-option-value skip-if)
        if [[ ! -z $func ]]; then
            if $($func); then
                log-info karmah "skipping $target_path because $func returned true"
                return
            fi
        fi
        local onlyfunc=$(get-option-value only-if)
        if [[ ! -z $onlyfunc ]]; then
            if ! $($onlyfunc); then
                log-info karmah "skipping $target_path because $onlyfunc returned false"
                return
            fi
        fi
        run-actions "$action_list"
    else
        log-info karmah "skipping non existing path $target_path"
    fi
}

init-parent-karmah() {
    local parent=$1
    log-verbose karmah "init karmah of parent klass ${parent}"
    if $(function-exists $parent::init-klass); then
        current_klass=$parent $parent::init-klass
    else
        declare-parent-klass $parent
        current_klass=$parent $parent::init-karmah # for backward compatibility
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
}

load-karmah-file() {
    declare -g karmah_type
    if [[ ! -f "${karmah_file}" ]]; then
        log-info karmah "skipping $karmah_file"
        return
    fi

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
