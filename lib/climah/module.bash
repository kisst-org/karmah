
modules-init-climah-vars() {
    declare -g all_modules=""
    declare -gA module_summary=()
}

modules-init-climah-module() {
    help-add-topic mod modules  modules-show "show all modules"
}
modules-show() {
    cat <<EOF
karmah-develop help [<module>]

module can be any of:
EOF
    help-list-items module;
}

module-init() {
    local module="$1"
    if ${module_disabled[$module]:-false}; then
        debug skipping module $module because it is disabled
    elif [[ ${module_loaded[$module]:-false} == false ]]; then
        module_loaded[$module]=true
        all_modules+=" $module"
        help_level=basic
        debug running init module for "${module}"
        ${module}-init-climah-module
    fi
}

module-add-help() {
    local short=$1 summary="${2:-info about module $module}" key
    module_summary[$module]=$summary
    help-add-item module "$short" $module "" "$summary"
    local help_func=modules-show-help-about-module
    #if [[ $(type -t $modules-show-help-about-module) == function ]]; then
    #    help_func=$modules-show-help-about-module
    #fi
    for key in $module module:$module; do
        help_topic_function[$key]=$help_func
        help_topic_params[$key]=$module;
    done
}

modules-show-help-about-module() {
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

module-init-all() {
    declare -g modules=""
    declare -gA module_loaded=()
    declare -gA module_disabled=()

    local func m
    # first declare any variables that might be used in other modules
    local var_funcs=$(set | grep '[-]init-climah-vars')
    for func in $var_funcs; do
        ${func##()}
    done

    config-pre-module-init

    # Then load modules, that may need variable from other modules
    local m mod=$(set | grep '[-]init-climah-module ()'| sed -e 's/[-]init-climah-module.*//')
    verbose loading modules: $mod
    for m in "$@" $mod; do
        module-init $m
    done
}

module-disable() {
   for m in "${@}"; do
      debug disabling module $m
      module_disabled[$m]=true;
   done
}
