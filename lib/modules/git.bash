
git::init-module() {
    add-module-help "actions to work with git"
    help_level=expert
    declare-action gd git-diff     "shows the changes to source and rendered manifests with git"
    declare-action ga git-add      "adds the changes to source and rendered manifests to git, for committing"
    declare-action gc git-commit   "commits the changes to source and rendered manifests to git"
    declare-action gr git-restore  "restores the changed files (source and rendered manifests)"
    declare-action "" git-pull     "pull the latest version of the repo"
    add-value-option m   message        msg   "set message to use with git commit"
    add-flag-option Q quiet-diff "do not show the output of diff"
    local_vars+=" used_files git_commit_message"
}

git-add-message() {
    if [[ -z ${git_commit_message:-} ]] then
        git_commit_message="${1}"
    else
        git_commit_message+=", ${1}"
    fi
    log-debug git "commmit message is: $git_commit_message"
}

run-git() { run-verbose-cmd git "$@"; }

action::git-pull() {
    log-info git "git-pull"
    run-git pull
}

action::git-diff() {
    local quiet_diff=$(get-option-value quiet-diff false)
    log-info git "git-diff ${output_dir} ..."
    if ${quiet_diff}; then
        run-git diff --compact-summary -- ${used_files} ${output_dir} || true
    elif $(log-shows-debug); then
        run-git diff -- ${used_files} ${output_dir} || true
    elif $(log-shows-verbose); then
        run-git diff -- ${used_files} ${output_dir} | grep -E '^[+-]|^---' || true
    else
        run-git diff --compact-summary -- ${used_files} ${output_dir} || true
    fi
}

action::git-add() {
    local tmp=$(get-option-value tmp false)
    if $tmp; then
        log-info git "skipping git-add because --tmp specfied"
        return
    fi
    log-info git "git-add ${output_dir} ..."
    run-git add ${used_files} ${output_dir}
}
action::git-restore() {
    # TODO: find better way to determine if path is tracked
    if [[ $output_dir == tmp/* ]]; then
        # git restore gives pathspec error on untracked paths
        log-info git "git-restore ${used_files}"
        run-git restore ${used_files}
    else
        log-info git "git-restore ${used_files} ${output_dir}"
        run-git restore ${used_files} ${output_dir}
        run-git clean --force ${output_dir}  # remove any files that were not there initially
    fi
}

action::git-status() {
    git status
}

action::git-commit() {
    run-actions git-add
    local tmp=$(get-option-value tmp false)
    local message=$(get-option-value message)
    if $tmp; then
        log-info git "skipping git-commit because --tmp specified"
        return
    fi
    : ${git_commit_message:=${action} of ${target_name}}
    if [[ ! -z $message ]]; then
        git-add-message "$message"
    fi
    log-info git "git-commit with message \"$git_commit_message\""
    # TODO: simulate ???
    if git diff-index --quiet HEAD; then
        log-info git "Nothing added to commit"
    else
        run-verbose-cmd git commit -m "${git_commit_message}" ${used_files} ${output_dir}
    fi
}
