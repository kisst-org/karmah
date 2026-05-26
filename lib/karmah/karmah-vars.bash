
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
