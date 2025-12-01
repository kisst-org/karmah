
init_climah_vars_git() {
    declare -g git_pulled=false
}

init_climah_module_git() {
    help_level=expert
    add-action gd git-diff     update,render  "shows the changes to source and rendered manifests with git"
    add-action ga git-add      update,render  "adds the changes to source and rendered manifests to git, for committing"
    add-action gc git-commit   update,render,git-add  "commits the changes to source and rendered manifests to git"
    add-action gr git-restore  ""             "restores the changed files (source and rendered manifests)"
    add-value-option m fixed-message    msg   "set fixed message to use with git commit"
    add-value-option M prepend-message  msg   "prepend commit message before auto generated message"
    add-flag-option Q quiet-diff "do not show the output of diff"
    local_vars+=" used_files git_commit_message"
}

parse-option-message()   { fixed_message="$2";   parse_result=2; }
parse-option-prepend-message()   { prepend_message="$2";   parse_result=2; }
add_message() {
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message="${prepend_message:-}"
    fi
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message+="${1}"
    else
        git_commit_message+=", ${1}"
    fi
    debug "commmit message is: $git_commit_message"
}

run-action-git-pull() {
    verbose_cmd git pull
}

run-action-git-diff() {
    info git-diff ${target} to ${output_dir}
    if ${quiet_diff:-false}; then
        verbose_cmd git diff --compact-summary -- ${used_files} ${output_dir} || true
    elif $(log_is_debug); then
        verbose_cmd git diff -- ${used_files} ${output_dir} || true
    elif $(log_is_verbose); then
        verbose_cmd git diff -- ${used_files} ${output_dir} | grep -E '^[+-]|^---' || true
    else
        verbose_cmd git diff --compact-summary -- ${used_files} ${output_dir} || true
    fi
}

run-action-git-add() {
    if $tmp; then
        info skipping git-add because --tmp specfied
        return
    fi
    info git-add ${target} to ${output_dir}
    verbose_cmd git add ${used_files} ${output_dir}
}
run-action-git-restore() {
    # TODO: find better way to determine if path is tracked
    if [[ $output_dir == tmp/* ]]; then
        # git restore gives pathspec error on untracked paths
        info git-restore ${used_files}
        verbose_cmd git restore ${used_files}
    else
        info git-restore ${used_files} ${output_dir}
        verbose_cmd git restore ${used_files} ${output_dir}
        verbose_cmd git clean --force ${output_dir}  # remove any files that were not there initially
    fi
}

run-action-git-status() {
    git status
}


run-action-git-commit() {
    if $tmp; then
        info skipping git-commit because --tmp specfied
        return
    fi
    if [[ ! -z ${fixed_message:-} ]]; then
        git_commit_message=$fixed_message
    fi
    : ${git_commit_message:=${action} of ${target}}
    if git diff-index --quiet HEAD; then
        verbose Nothing added to commit for message: "${git_commit_message}"
    else
        verbose_cmd git commit -m "${git_commit_message}" ${used_files} ${output_dir}
    fi
}
