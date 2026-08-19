
karmah-var::declare-vars() {
    declare -gA karmah_var_module=()
    declare -gA karmah_var_option_value=()
}

karmah-var::init-module() {
    append-argparse-func parse-if-karmah-var
}

add-karmah-var() { declare-karmah-var "$@"; } # TODO: to be deprecated
declare-karmah-var() {
    local short=$1 name=$2 arg=$3 summary="${4:-}"
    karmah_var_module[$name]=$module
    if [[ ! -z $short ]]; then
        short=-$short
        argparse-add-short $short --$name
    fi
    add-help-item "$short" $name karmah-var:--${name//_/-} "$arg" "$summary"
    karmah_var_list+=" $name"
}

parse-if-karmah-var() {
    local arg=${1#--}
    if [[ $arg == $1 ]]; then return 0; fi  # not an karmah-var starting with --...
    if [[ -z  $arg ]]; then return 0; fi  # ignore -- option

    local name=${arg/=*/}
    local varname=${name//-/_}
    if [[ -z ${karmah_var_module[$varname]:-} ]]; then return 0; fi   # not a known karmah-var
    local value=${arg/*=/}
    argparse_parse_count=1
    if [[ $value == $arg ]]; then
        argparse_parse_count=2
        value=$2
    fi
    karmah_var_option_value[$varname]="$value"
}

use-karmah-var() {
    local varname=$1 default="${2:-}"
    if [[ -z ${karmah_var_module[$varname]:-} ]]; then
        log-error karmah "code refers to unknown karmah-var $varname"
        exit 1
    fi
    local default_varname=default_$varname
    if [[ ! -z ${karmah_var_option_value[$varname]:-} ]]; then
        value="${karmah_var_option_value[$varname]}"
    elif [[ ! -z $(get-karmah-var-from-env $varname) ]]; then
        value="$(get-karmah-var-from-env $varname)"
    elif [[ ! -z ${!varname:-} ]]; then
        value="${!varname}"
    elif [[ ! -z ${!default_varname:-} ]]; then
        value="${!default_varname}"
    else
        value="$default"
    fi
    log-debug karvar "setting karmah value $varname to $value"
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
