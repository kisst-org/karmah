
modules::declare-vars() {
    declare -g all_modules=""
}

modules-show() {
    cat <<EOF
$climah_prog_name help [<module>]

module can be any of:
EOF
    list-help-items module;
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
require-modules() {
    local mod
    for mod in "${@}"; do
        init-module $mod
    done
}

add-module-help() {
    local summary="${1:-info about module $module}" key
    add-help-item module $module "" "$summary"
}

show-help-section() {
    local type=$1 header=${2:-}
    if $(has-help-items $type); then
        echo "${header:-${type}s:}"
        list-help-items $type
        echo
    fi
}

show-help-about-module() {
    local type=$1 name=$2
    echo module $name: ${help_item_summary[module:$name]:-no summary}
    help_show_level=all ;
    help_show_module=$name
    show-help-section command
    show-help-section action
    #show-help-section flow
    show-help-section option
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
