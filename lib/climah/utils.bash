# utils.bash
# some simple generic functions

add-commas() { local args="${*// /,}"; echo ${args%%,}; }
add-spaces() { local args="${*//,/ }"; echo ${args%% }; }

function-exists() {
    if  [[ $(type -t $1) == function ]]; then
        echo true
    else
        echo false
    fi
}
