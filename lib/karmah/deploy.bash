
init_climah_module_deploy() {
    add-action "" deploy "render to deployed/manifests and optionally deploy to kubernetes"
    add-action "" plan   "show what deploy action would do"
    help_level=expert
    add-action no-cmd ask "ask for confirmation (unless --yes is specified)"
    add-option y yes "" "do not ask for confirmation (with ask, kapp-deploy, ...)"
    yes_arg=""
}

parse-option-yes() { yes_arg="--yes"; }

run-action-ask() {
    if [[  $yes_arg == --yes ]]; then
        info skipping ask, because --yes is specified
        return 0
    fi
    local answer
    read -p "do you want to continue [y/N]? " answer
    if [[ "${answer}" != y ]] ;then
        info "Stopping karmah"
        exit 1
    fi
}

run-action-deploy() {
    output_dir=deployed/manifests/$target
    local actions=$(add-commas ${deploy_actions:-render,git-diff,ask,git-commit})
    verbose deploying ${output_dir} with actions: ${actions}
    add_message "deploy $target"
    # TODO: output_dir is different for actions before this action
    # should be first (only) action
    info "deploying $target with actions ${actions// /,}"
    run_actions $actions
}

run-action-plan() {
    local actions=$(add-commas ${plan_actions:-render,git-diff})
    info "planning deploy $target with actions: ${actions// /,}"
    run_actions $actions
}

run-command-undeploy() {
    output_dir="${to_dir:-deployed/manifests}/${target}"
    local actions=$(add-commas ${undeploy_actions:-render-rm,git-diff,ask,git-commit})
    info "undeploying ${target} with actions: ${actions}"
    run_actions $actions
}
