
init_climah_vars_modules() {
    declare -g all_modules=""
    declare -gA module_help=()
}

use_module() {
    local module="$1"
    if [[ ${module_loaded[$module]:-false} == false ]]; then
        module_loaded[$module]=true
        all_modules+=" $module"
        debug running init module for "${module}"
        init_climah_module_${module}
    fi
}

add-module-help() {
    module_help[$module]="$@";
}

init_all_modules() {
    declare -g modules=""
    declare -gA module_loaded=()

    local func m
    # first declare any variables that might be used in other modules
    local var_funcs=$(set | grep '^init_climah_vars_')
    for func in $var_funcs; do
        ${func##()}
    done

    # Then load modules, that may need variable from other modules
    local m mod=$(set | grep '^init_climah_module_'| sed -e 's/init_climah_module_//' -e 's/ *()//')
    for m in "$@" $mod; do
        help_level=basic
        use_module $m
    done
}

show-modules() {
    local mod
    for mod in $all_modules; do
        printf "  %-13s %s\n" $mod "${module_help[$mod]:-no help}"
    done
}
