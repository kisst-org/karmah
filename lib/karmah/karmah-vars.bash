
karmah-var::declare-vars() {
    declare -gA karmah_var_module=()
}

# karmah-var::init-module() {
#     append-argparse-func parse-if-karmah-var
# }

add-karmah-var() { declare-karmah-var "$@"; } # TODO: to be deprecated
declare-karmah-var() {
    local short=$1 name=$2 arg=$3 summary="${4:-}"
    local opt_name=${name//_/-}
    karmah_var_module[$name]=$module
    if [[ ! -z $short ]]; then
        short=-$short
        argparse-add-short $short --$name
    fi
    add-help-item "$short" $name karmah-var:--${opt_name} "$arg" "$summary"
    karmah_var_list+=" $name"
    option_func[$opt_name]=parse-value-option
}

use-karmah-var() {
    local vardef="$1" default="${2:-}"
    local varname=${vardef/:=*/}
    if [[ -z ${karmah_var_module[$varname]:-} ]]; then
        log-error karmah "code refers to unknown karmah-var $varname"
        exit 1
    fi
    local default_varname=default_$varname
    local optval=$(get-option-value ${varname//_/-})
    if [[ ! -z ${optval} ]]; then
        value="${optval}"
    elif [[ ! -z $(get-karmah-var-from-env $varname) ]]; then
        value="$(get-karmah-var-from-env $varname)"
    elif [[ ! -z ${!varname:-} ]]; then
        value="${!varname}"
    elif [[ ! -z ${!default_varname:-} ]]; then
        value="${!default_varname}"
    else
        value="$default"
    fi
    if [[ -z $value ]]; then
        if [[ $vardef == $varname ]]; then # no :=...
            log-warn karmah.var "mandatory karmah-var $varname for action $action is empty"
            # exit 1 # TODO, should it be possible to enable this
        else
            value="${vardef/*:=/}"
        fi
    fi
    log-debug karmah.var "setting karmah-var $varname to \"$value\""
    read $varname <<<"$value"
    # could also be declare -g $varname="$value"   or   eval $varname="$value"
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
