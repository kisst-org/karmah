# karmah: do stuff based on *.karmah file
karmah-main() {
    declare -g climah_prog=karmah
    # too many actions and options so only show some basic stuff
    default_module_help_level=expert
    basic_help_modules="loggers actions options commands"
    climah-main "$@"
}


karmah::declare-vars() {
    declare -g local_vars="karmah_type target_name"
    declare -g default_karmah_type=empty
    declare -gA karmah_var_names=()
}

karmah::init-module() {
    add-command "" version ""  "show version of karmah"
    climah_prog=karmah
    default_action=render
    help_level=expert
    add-action "" init-karmah "load *.karmah init file(s) and run ::init-target function"
    add-action "" clear-karmah "clear all karmah-vars"
    add-karmah-var "" karmah_type "<name>" "override any karmah_type declared in karmah files and init-karmah"
}

run-command-version() { echo karmah version: $karmah_version; }


empty::init-target() { verbose using empty karmah_type initializer; }

add-karmah-var() {
    local short=$1 name=$2 arg=$3 summary="${4:-}"
    karmah_var_names[$name]=$name
    #karmah_var_names[$module:$name]=$name
    #add-help-item karmah-var "$name" "$arg" "$summary"
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


add-karmah-action() {
    add-action "${@}"
    set-action-pre-flow init-karmah "$2"
}

action::init-karmah() {
    if [[ -f $target_path ]]; then
        karmah_file=$target_path
    elif [[ -d ${target_path:-} ]]; then
        karmah_file=($target_path/*.karmah) # use array for globbing
    else
        log-info karmah "skipping $target_path"
        # TODO: warn, error or skip_flow
        return 0
    fi
    declare -g used_karmah_vars=""
    load-karmah-file
    log-verbose karmah "calling ${karmah_type}::init-target"
    ${karmah_type}::init-target

    # TODO: output_dir does not belong here
    local tmp=$(get-option-value tmp false)
    output_dir="${to_dir:-tmp/manifests}/${target_name}"
    if $tmp; then
        output_dir="${to_dir:-tmp/manifests}/${target_name}"
    fi
    post_flow_actions+=" clear-karmah"
}
action::clear-karmah() {
    log-debug karmah "clearing karmah-vars: ${used_karmah_vars:-}"
    unset ${used_karmah_vars:-};
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
    used_files=${karmah_dir}
    local common_karmah_file=($common_dir/common*.karmah)
    if [[ -f $common_karmah_file ]]; then
        log-verbose karmah "loading $common_karmah_file"
        source $common_karmah_file
    fi
}
