
git::declare-vars() {
    declare -g git_pulled=false
}

git::init-climah-module() {
    add-module-help "actions to work with git"
    help_level=expert
    add-render-action gd git-diff     "shows the changes to source and rendered manifests with git"
    add-render-action ga git-add      "adds the changes to source and rendered manifests to git, for committing"
    add-render-action gc git-commit   "commits the changes to source and rendered manifests to git"
    add-render-action gr git-restore  "restores the changed files (source and rendered manifests)"
    add-value-option m   message        msg   "set message to use with git commit"
    add-value-option M prepend-message  msg   "prepend commit message before auto generated message"
    add-flag-option Q quiet-diff "do not show the output of diff"
    set-action-pre-flow load-karmah,update,render           git-diff git-add
    set-action-pre-flow load-karmah,update,render,git-add   git-commit
    local_vars+=" used_files git_commit_message"
}

parse-option-prepend-message()   { prepend_message="$2";   argparse_parse_count=2; }
git-add-message() {
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message="${prepend_message:-}"
    fi
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message+="${1}"
    else
        git_commit_message+=", ${1}"
    fi
    log-debug git "commmit message is: $git_commit_message"
}

run-action-git-pull() {
    log-info git "running git-pull for $target_name"
    verbose-cmd git pull
}

run-action-git-diff() {
    log-info git "git-diff ${target_name} to ${output_dir}"
    if ${quiet_diff:-false}; then
        verbose-cmd git diff --compact-summary -- ${used_files} ${output_dir} || true
    elif $(log-is-debug); then
        verbose-cmd git diff -- ${used_files} ${output_dir} || true
    elif $(log-is-verbose); then
        verbose-cmd git diff -- ${used_files} ${output_dir} | grep -E '^[+-]|^---' || true
    else
        verbose-cmd git diff --compact-summary -- ${used_files} ${output_dir} || true
    fi
}

run-action-git-add() {
    if $tmp; then
        log-info git "skipping git-add because --tmp specfied"
        return
    fi
    log-info git "git-add ${target_name} to ${output_dir}"
    verbose-cmd git add ${used_files} ${output_dir}
}
run-action-git-restore() {
    # TODO: find better way to determine if path is tracked
    if [[ $output_dir == tmp/* ]]; then
        # git restore gives pathspec error on untracked paths
        log-info git "git-restore ${used_files}"
        verbose-cmd git restore ${used_files}
    else
        log-info git "git-restore ${used_files} ${output_dir}"
        verbose-cmd git restore ${used_files} ${output_dir}
        verbose-cmd git clean --force ${output_dir}  # remove any files that were not there initially
    fi
}

run-action-git-status() {
    git status
}


run-action-git-commit() {
    if $tmp; then
        log-info git "skipping git-commit because --tmp specified"
        return
    fi
    log-info git "running git-commit for $target_name"
    : ${git_commit_message:=${action} of ${target_name}}
    if git diff-index --quiet HEAD; then
        verbose Nothing added to commit for message: "${git_commit_message}"
    else
        verbose-cmd git commit -m "${git_commit_message}" ${used_files} ${output_dir}
    fi
}
