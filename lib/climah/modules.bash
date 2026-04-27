
init-module-system() {
    declare -g modules=""
    declare -gA module_loaded=()
    declare -gA module_disabled=()
    declare -g all_modules=""
    declare -gA module_help_level=()
    #: ${default_module_help_level:=basic}
    local mod; for mod in ${disable_modules:-}; do
        module_disabled[$mod]=true
    done
    local mod; for mod in ${basic_help_modules:-}; do
        module_help_level[$mod]=basic
    done
}

modules-show() {
    cat <<EOF
$climah_prog_name help [<module>]

module can be any of:
EOF
    list-help-items module
}

init-module() {
    local module="$1"

    if ${module_disabled[$module]:-false}; then
        log-debug modules "skipping module $module because it is disabled"
    elif [[ ${module_loaded[$module]:-false} == false ]]; then
        module_loaded[$module]=true
        all_modules+=" $module"
        help_level=${module_help_level[$module]:-${default_module_help_level:-basic}}
        log-debug modules "running init module for ${module}"
        ${module}::init-module
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
    add-help-item $module module:$module "" "$summary"
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
    help_show_level=all
    help_show_module=$name
    show-help-section command
    show-help-section action
    #show-help-section flow
    show-help-section option
}



declare-all-module-vars() {
    init-module-system
    #local func # TODO remove
    # first declare any variables that might be used in other modules
    local var_modules=$(set | grep -E '^[A-Za-z-]*::declare-vars'| sed -e 's/::declare-vars.*//')
    log-debug modules "init-vars: $var_modules"
    local mod; for mod in $var_modules; do
        if ! ${module_disabled[$mod]:-false}; then
            ${mod}::declare-vars
        fi
    done
    config-pre-module-init
}

init-all-modules() {
    # Then load modules, that may need variable from other modules
    local modules=$(set | grep -E '^[A-Za-z-]*::init-module ()'| sed -e 's/::init-module.*//')
    log-debug modules "loading modules: $modules"
    local mod; for mod in "$@" $modules; do
        if ! ${module_disabled[$mod]:-false}; then
            init-module $mod
        fi
    done
}
