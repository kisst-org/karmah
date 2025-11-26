
load_module() {
    file="$1"
    shift
    if [[ ${module_files["${file}"]:-} == loaded ]]; then
        verbose skipping module file "${file}" already loaded
        return 0
    fi
    module_files["${file}"]=loaded
    local filename="$(basename "${file}")"
    local module="${filename%%.lib}"
    verbose loading module "${module}" from "${file}"
    source "${file}"
}

use_module() {
    local module="$1"
    if ${module_needs_init["${module}"]:-true}; then
        debug running init module for "${module}"
        init_climah_module_${module}
        module_needs_init["${module}"]=false
    fi
}

init_all_modules() {
    declare -g modules=""
    declare -gA module_needs_init=()
    declare -gA module_files=()

    local func m
    # first declare any variables that might be used in other modules
    local var_funcs=$(set | grep '^init_climah_vars_')
    for func in $var_funcs; do
        ${func##()}
    done

    # Then load modules, that may need variable from other modules
    modules=$(set | grep '^init_climah_module_'| sed -e 's/init_climah_module_//' -e 's/ *()//')
    for m in $modules; do
        help_level=basic
        use_module $m
    done
}
