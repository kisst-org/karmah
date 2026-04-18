
modules::declare-vars() {
    declare -g all_modules=""
    declare -gA module_summary=()
}

modules::init-climah-module() {
    help-add-topic mod modules  modules-show "show all modules"
}
modules-show() {
    cat <<EOF
$climah_prog_name help [<module>]

module can be any of:
EOF
    help-list-items module;
}

init-module() {
    local module="$1"
    if ${module_disabled[$module]:-false}; then
        debug skipping module $module because it is disabled
    elif [[ ${module_loaded[$module]:-false} == false ]]; then
        module_loaded[$module]=true
        all_modules+=" $module"
        help_level=basic
        debug running init module for "${module}"
        ${module}::init-climah-module
    fi
}

add-module-help() {
    local summary="${1:-info about module $module}" key
    module_summary[$module]=$summary
    help-add-item module $module "" "$summary"
    local help_func=show-help-about-module
    for key in $module module:$module; do
        help_topic_function[$key]=$help_func
        help_topic_params[$key]=$module;
    done
}

show-help-about-module() {
    help_show_level=expert;
    help_show_module=$1
    echo "commands:"
    help-list-items command
    echo
    echo "actions:"
    help-list-items action
    echo
    echo "options:"
    help-list-items option
}

init-all-modules() {
    declare -g modules=""
    declare -gA module_loaded=()
    declare -gA module_disabled=()

    local func m
    # first declare any variables that might be used in other modules
    local var_modules=$(set | grep -E '^[A-Za-z-]*::declare-vars'| sed -e 's/::declare-vars.*//')
    debug init-vars: $var_modules
    for m in $var_modules; do
        ${m}::declare-vars
    done

    config-pre-module-init

    # Then load modules, that may need variable from other modules
    local m mod=$(set | grep -E '^[A-Za-z-]*::init-climah-module ()'| sed -e 's/::init-climah-module.*//')
    debug loading modules: $mod
    for m in "$@" $mod; do
        init-module $m
    done
}

module-disable() {
   for m in "${@}"; do
      debug disabling module $m
      module_disabled[$m]=true;
   done
}
