
init_climah_vars_git() {
    declare -g git_pulled=false
}

init_climah_module_git() {
    add_action git-diff "shows the changes to source and rendered manifests with git"
    add_action git-add "adds the changes to source and rendered manifests to git, for committing"
    add_action git-commit "commits the changes to source and rendered manifests to git"
    add_option m message  msg   set fixed message to use with git commit
    add_option M prepend-message  msg   prepend commit message before auto generated message
    global_vars+=" used_files git_commit_message"
}

parse_option_message()   { git_fixed_message="$2";   parse_result=2; }
parse_option_prepend-message()   { git_prepend_message="$2";   parse_result=2; }
add_message() {
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message="${git_prepend_message:-}"
    fi
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message+="${1}"
    else
        git_commit_message+=", ${1}"
    fi
    debug "commmit message is: $git_commit_message"
}

run_action_git-pull() {
    verbose_cmd git pull
}

run_action_git-diff() {
    info git-diff ${target} to ${output_dir}
    if $(log_is_debug); then
        verbose_cmd git diff -- ${used_files} ${output_dir} || true
    elif $(log_is_verbose); then
        verbose_cmd git diff -- ${used_files} ${output_dir} | grep -E '^[+-]|^---' || true
    else
        verbose_cmd git diff --compact-summary -- ${used_files} ${output_dir} || true
    fi
}

run_action_git-add() {
    info git-add ${target} to ${output_dir}
    verbose_cmd git add ${used_files} ${output_dir}
}

run_action_git-status() {
    git status
}


run_action_git-commit() {
    run_action_git-add
    if [[ ! -z ${git_fixed_message:-} ]]; then
        git_commit_message=$git_fixed_message
    fi
    : ${git_commit_message:=${action} of ${target}}
    if git diff-index --quiet HEAD; then
        verbose Nothing added to commit
    else
        verbose_cmd git commit -m "${git_commit_message}" ${used_files} ${output_dir}
    fi
}
