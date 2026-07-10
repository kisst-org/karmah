# utils.bash
# some simple generic functions

add-commas() { local args="${*// /,}"; echo ${args%%,}; }
add-spaces() { local args="${*//,/ }"; echo ${args%% }; }

# returns first argument only when it is not in one of remaining arguments
# prefix with a space if there are other elements
# to be used to append to a list if it is not in there yet
#   list+=$(iif-unique-in-list value $list)
iif-unique-in-list() {
    local first=$1; shift
    local prefix=""
    for i in $*; do
        if [[ $first == $i ]]; then
            echo ""
            return
        fi
        prefix=" "
    done
    echo $prefix$first
}

add-map-value() {
    local map_name=$1 map_idx=$2 value=$3 handler=${4:-warn} dupl_handler=${5:-debug}
    local oldval="$(eval "echo \${$map_name[$map_idx]:-}")"
    if [[ -z $oldval ]]; then
        log-debug ${module:-util} "adding $map_name[$map_idx]=\"$value\""
        eval "$map_name[$map_idx]=\"$value\""
        return 0
    elif [[ $oldval == $val ]]; then
        local msg="$map_name duplicate try to set value \"$oldval\" for $map_idx"
        handler=$dupl_handler
    else
        local msg="$map_name already has value \"$oldval\" for $map_idx when trying to set to $value"
    fi
    $handler "$msg";
    if [[ $handler == error ]]; then exit 1; fi
}
change-map-value() {
    local map_name=$1 map_idx=$2 value=$3 handler=${4:-warn}
    local oldval="$(eval "echo \${$map_name[$map_idx]:-}")"
    if [[ ! -z $oldval ]]; then
        log-debug ${module:-util} "changing $map_name[$map_idx]=\"$value\""
        eval "$map_name[$map_idx]=\"$value\""
        return 0
    fi
    local msg="$map_name already has value \"$oldval\" for $map_idx when trying to set to $value"
    $handler "$msg";
    if [[ $handler == error ]]; then exit 1; fi
}

function-exists() {
    if  [[ $(type -t $1) == function ]]; then
        echo true
    else
        echo false
    fi
}
