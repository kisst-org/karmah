
deploy-init-climah-module() {
    add-karmah-action "" deploy "render to deployed/manifests and optionally deploy to kubernetes"
    add-karmah-action "" plan   "show what deploy action would do"
    help_level=expert
    add-karmah-action "" ask "ask for confirmation (unless --yes is specified)"
    add-option y yes "" "do not ask for confirmation (with ask, kapp-deploy, ...)"
    yes_arg=""
    add-module-help "actions to work with deploy/plan"
}
deploy-show-help() { help-show-module deploy; }

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
    output_dir=deployed/manifests/$target_name
    local actions=$(add-commas ${deploy_actions:-render,git-diff,ask,git-commit})
    verbose deploying ${output_dir} with actions: ${actions}
    git-add-message "deploy $target_name"
    # TODO: output_dir is different for actions before this action
    # should be first (only) action
    info "deploying $target_name with actions ${actions// /,}"
    run-actions $actions
}

run-action-plan() {
    local actions=$(add-commas ${plan_actions:-render,git-diff})
    info "planning deploy $target_name with actions: ${actions// /,}"
    run-actions $actions
}

run-command-undeploy() {
    output_dir="${to_dir:-deployed/manifests}/${target_name}"
    local actions=$(add-commas ${undeploy_actions:-render-rm,git-diff,ask,git-commit})
    info "undeploying ${target_name} with actions: ${actions}"
    run-actions $actions
}
