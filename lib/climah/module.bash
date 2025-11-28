
use_module() {
    local module="$1"
    if [[ ${module_loaded[$module]:-false} == false ]]; then
        module_loaded[$module]=true
        all_modules+=" $module"
        debug running init module for "${module}"
        init_climah_module_${module}
    fi
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
