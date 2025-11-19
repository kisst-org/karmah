
init_bash_module_deploy() {
    add_action ask "ask for confirmation (unless --yes is specified)"
    add_action deploy "render to deployed/manifests and optionally deploy to kubernetes"
    add_option a action act  add action to list of actions to perform
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
    # TODO: output_dir is different for actions before this action
    run_actions $actions
}
