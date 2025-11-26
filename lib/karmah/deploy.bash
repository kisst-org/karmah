
init_climah_module_deploy() {
    add_action deploy "render to deployed/manifests and optionally deploy to kubernetes"
    add_action plan   "show what deploy action would do"
    help_level=expert
    add_action ask "ask for confirmation (unless --yes is specified)"
    add_option y yes    ""   do not ask for confirmatopm
    yes_arg=""
}

parse_option_action() { action_list+=" $2"; parse_result=2; }
parse_option_yes()    { yes_arg="--yes"; }

run_action_ask() {
    if [[  $yes_arg == --yes ]]; then
        verbose skipping ask, because --yes is specified
        return 0
    fi
    local answer
    read -p "do you want to continue [y/N]? " answer
    if [[ "${answer}" != y ]] ;then
        info "Stopping karmah"
        exit 1
    fi
}



run_action_deploy() {
    output_dir="${to_dir:-deployed/manifests}/${target}"
    local actions=${deploy_actions:-render,git-diff,ask,git-commit}
    info deploying ${output_dir} with actions: ${actions}
    add_message "deploy $target"
    # TODO: output_dir is different for actions before this action
    # should be first (only) action
    run_actions $actions
}

run_action_plan() {
    output_dir="${to_dir:-deployed/manifests}/${target}"
    local actions=${plan_actions:-render,git-diff}
    info planning deploy ${output_dir} with actions: ${actions}
    run_actions $actions
}

run_action_undeploy() {
    output_dir="${to_dir:-deployed/manifests}/${target}"
    local actions=${undeploy_actions:-render-rm,git-diff,ask,git-commit}
    info undeploying ${output_dir} with actions: ${actions}
    run_actions $actions
}
