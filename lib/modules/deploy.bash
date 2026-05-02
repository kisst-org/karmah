
deploy::init-module() {
    add-module-help "actions to work with deploy/plan"
    add-karmah-action "" deploy "render to deployed/manifests and optionally deploy to kubernetes"
    add-karmah-action "" plan   "show what deploy action would do"
    help_level=expert
    add-karmah-action "" ask "ask for confirmation (unless --yes is specified)"
    add-func-option y yes "" "do not ask for confirmation (with ask, kapp-deploy, ...)"
    yes_arg=""
}

parse-option-yes() { yes_arg="--yes"; }

action::ask() {
    if [[  $yes_arg == --yes ]]; then
        log-info deploy "skipping ask, because --yes is specified"
        return 0
    fi
    local answer
    read -p "do you want to continue [y/N]? " answer
    if [[ "${answer}" != y ]] ;then
        log-info deploy "Stopping karmah"
        exit 1
    fi
}

action::deploy() {
    output_dir=deployed/manifests/$target_name
    local actions=$(add-commas ${deploy_actions:-render,git-diff,ask,git-commit})
    log-verbose deploy "deploying ${output_dir} with actions: ${actions}"
    git-add-message "deploy $target_name"
    # TODO: output_dir is different for actions before this action
    # should be first (only) action
    log-info deploy "deploying $target_name with actions ${actions// /,}"
    run-single-actions $actions
}

action::plan() {
    local actions=$(add-commas ${plan_actions:-render,git-diff})
    log-info deploy "planning deploy $target_name with actions: ${actions// /,}"
    run-single-actions $actions
}

run-command-undeploy() {
    output_dir="${to_dir:-deployed/manifests}/${target_name}"
    local actions=$(add-commas ${undeploy_actions:-render-rm,git-diff,ask,git-commit})
    log-info deploy "undeploying ${target_name} with actions: ${actions}"
    run-single-actions $actions
}
