
git::init-module() {
    add-module-summary "actions to work with git"
    help_level=expert
    declare-action gd git-diff     "shows the changes to source and rendered manifests with git"
    declare-action ga git-add      "adds the changes to source and rendered manifests to git, for committing" \
        set-vars:git_used_paths,git_changed_paths
    declare-action gc git-commit   "commits the changes to source and rendered manifests to git" \
        set-vars:git_commit_message
    declare-action gr git-restore  "restores the changed files (source and rendered manifests)" \
        set-vars:git_changed_paths
    declare-action "" git-pull     "pull the latest version of the repo"
    add-value-option m   message            msg   "set message to use with git commit"
    add-flag-option  Q   git-quiet-diff           "do not show the output of diff"
    add-flag-option  U   git-add-used-paths       "add (and thus commit) any paths that might have been used, next to changed paths"
    add-karmah-var   ""  git_used_paths     path  "a list of paths that were used, and might need to be committed"
    add-karmah-var   ""  git_changed_paths  path  "a list of paths that were changed, and might need to be committed"
    add-karmah-var   ""  git_commit_message msg   "the message for a git commit, often automatically filled"
}
change-paths() {
    local p; for p in "$@"; do
        if [[ ! $p == tmp/* ]]; then
            changed_paths+=" $p"
        fi
    done
}
use-paths()    { git_used_paths+=" $*"; }

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
    local quiet_diff=$(get-option-value git-quiet-diff false)
    log-info git "git-diff ${changed_paths:-} ..."
    if [[ -z ${changed_paths:-} ]]; then
        log-warn git "no paths specfied to diff"
        return 0;
    fi
    if ${quiet_diff}; then
        run-git diff --compact-summary -- ${changed_paths} || true
    elif $(log-shows-debug); then
        run-git diff -- ${changed_paths} || true
    elif $(log-shows-verbose); then
        run-git diff -- ${changed_paths} | grep -E '^[+-]|^---' || true
    else
        run-git diff --compact-summary -- ${changed_paths} || true
    fi
}

action::git-add() {
    local commit_used_paths=$(get-option-value commit-used-paths false)
    local paths_to_add="${changed_paths:-}"
    local params=""
    if $commit_used_paths; then
        paths_to_add+=" ${git_used_paths:-}"
        # only show ellipses to keep log short
        params=" ..."
    fi
    local tmp=$(get-option-value tmp false)
    if $tmp; then
        log-info git "skipping git-add because --tmp specfied"
        return
    fi
    log-info git "git-add ${changed_paths:-}$params"
    if [[ -z ${paths_to_add:-} ]]; then
        log-warn git "no paths specified to add"
        return 0;
    fi
    run-git add ${paths_to_add}
}
action::git-restore() {
    # TODO: find way to determine if path is tracked
    log-info git "git-restore ${changed_paths:-}"
    if [[ -z ${changed_paths:-} ]]; then
        log-warn git "no paths specfied to restore"
        return 0;
    fi
    run-git restore ${changed_paths}
    # TODO run-git clean --force ${manifest_dir}  # remove any files that were not there initially
}

action::git-status() {
    git status
}

action::git-commit() {
    run-pre-actions git-add
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
        run-verbose-cmd git commit -m "${git_commit_message}"
    fi
}
