# karmah: do stuff based on *.karmah file
karmah-main() {
    declare -g used_karmah_vars=""
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
    declare -g local_vars="karmah_type target_name"
    declare -g default_karmah_type
    declare -gA karmah_var_names=()
    declare -g karmah_parent_classes=""
}

karmah::init-module() {
    add-command "" version ""  "show version of karmah"
    add-command run run-karmah-actions "" "run one or more actions for all targets"
    climah_prog=karmah
    default_action=render
    help_level=expert
    declare-action "" init-karmah "load *.karmah init file(s) and run ::init-karmah function"
    declare-action "" clear-karmah "clear all karmah-vars"
    add-karmah-var "" karmah_type "<name>" "override any karmah_type declared in karmah files and init-karmah"
    log-verbose ifed "default_karmah_type=${default_karmah_type:-base}"
    default_command=run-karmah-actions
}

command::version() { echo karmah version: $karmah_version; }
command::run-karmah-actions() { run-func-for-targets run-karmah-actions; }
run-karmah-actions() {
    declare -A action_already_run=()
    run-actions "init-karmah,$action_list,clear-karmah"
}

init-parent-karmah() {
    local typ=$1
    karmah_parent_classes+=" $typ"
    log-verbose karmah "calling ${typ}::init-karmah"
    $typ::init-karmah
}

base::init-karmah() { log-verbose karmah "using base karmah_type initializer"; }

#karmah-parents() { echo ${karmah_parent_classes:-} base; }
karmah-classes() { echo $karmah_type ${karmah_parent_classes:-} base; }
#call-karmah-method() {
#    local method=${1:-}; shift
#    local typ; for typ in $(karmah-classes); do
#        if $(function-exists $typ::$method); then
#            $typ::$method "$@"
#            return
#        fi
#    done
#}



add-karmah-var() {
    local short=$1 name=$2 arg=$3 summary="${4:-}"
    karmah_var_names[$name]=$name
    #karmah_var_names[$module:$name]=$name
    #add-help-item "$short" karmah-var "$name" "$arg" "$summary"
    add-value-option "$short" ${name//_/-} "${arg:-'<val>'}" "${summary:- set karmah-var $name}"
    used_karmah_vars+=" $name"
}

use-karmah-var() {
    local varname=$1 default="${2:-}"
    if [[ -z ${karmah_var_names[$varname]:-} ]]; then
        log-error karmah "code refers to unknown karmah-var $varname"
        exit 1
    fi
    declare -g $varname=$(get-karmah-var $varname "${default}")
}
get-karmah-var() {
    local varname=$1 default="${2:-}"  # error if not found and no default???
    local default_varname=default_$varname
    if [[ ! -z $(get-option-value ${varname//_/-}) ]]; then
        echo "$(get-option-value ${varname//_/-})"
    elif [[ ! -z $(get-karmah-var-from-env $varname) ]]; then
        echo "$(get-karmah-var-from-env $varname)"
    elif [[ ! -z ${!varname:-} ]]; then
        echo "${!varname}"
    elif [[ ! -z ${!default_varname:-} ]]; then
        echo "${!default_varname}"
    else
        echo "$default"
    fi
}

get-karmah-var-from-env() {
    local name=${1^^}
    local result=""
    local varname=${name/*:/}
    local v; for v in $varname ${module^^}__$varname; do
        local env_varname=KARMAH_VAR_${v//-/_}
        result=${!env_varname:-$result}
    done
    echo $result
}

action::init-karmah() {
    if [[ -f $target_path ]]; then
        karmah_file=$target_path
    elif [[ -d ${target_path:-} ]]; then
        karmah_file=($target_path/*.karmah) # use array for globbing
    else
        log-info karmah "skipping $target_path"
        # TODO: warn, error or skip
        return 0
    fi
    load-karmah-file
    log-verbose karmah "calling ${karmah_type}::init-karmah"
    ${karmah_type}::init-karmah

    # TODO: output_dir does not belong here
    local tmp=$(get-option-value tmp false)
    output_dir="${to_dir:-tmp/manifests}/${target_name}"
    if $tmp; then
        output_dir="${to_dir:-tmp/manifests}/${target_name}"
    fi
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
    log-verbose karmah "using karmah-type $karmah_type"
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
