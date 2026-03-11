
modules-init-climah-vars() {
    declare -g all_modules=""
    declare -gA module_help=()
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

add-module-help() {
    module_help[$module]="$@";
    if [[ $(type -t $module-show-help) == function ]]; then
        help-add-topic "" $module $module-show-help "info about module $module"
    fi
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

show-modules() {
    local mod
    for mod in $all_modules; do
        printf "  %-13s %s\n" $mod "${module_help[$mod]:-no help}"
    done
}

module-disable() {
   for m in "${@}"; do
      debug disabling module $m
      module_disabled[$m]=true;
   done
}
