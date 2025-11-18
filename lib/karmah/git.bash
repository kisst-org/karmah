
init_bash_module_git() {
    use_module render
    declare -g used_files=""
    declare -g git_pulled=false
    add_action git-diff "shows the changes to source and rendered manifests with git"
    add_action git-add "adds the changes to source and rendered manifests to git, for committing"
    add_action git-commit "commits the changes to source and rendered manifests to git"

    add_option m message  msg   set message to us with git commit
    global_vars+=" used_files"  # TODO: git_commit_message
}

parse_option_message()   { git_commit_message="$2";   parse_result=2; }

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
    : ${git_commit_message:=${action} of ${target}}
    verbose_cmd git commit -m "${git_commit_message}" ${used_files} ${output_dir}
}
