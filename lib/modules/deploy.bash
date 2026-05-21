
deploy::init-module() {
    add-module-help "actions to work with deploy/plan"
    declare-action "" deploy "render to deployed/manifests and optionally deploy to kubernetes"
    declare-action "" plan   "show what deploy action would do"
    help_level=expert
    declare-action     "" ask    "ask for confirmation (unless --yes is specified)"
    add-func-option y yes "" "do not ask for confirmation (with ask, kapp-deploy, ...)"
    yes_arg=""
}

option::yes() { yes_arg="--yes"; }

action::ask() {
    if [[  $yes_arg == --yes ]]; then
        log-info deploy "ask skipped, because --yes is specified"
        return 0
    fi
    local answer
    read -p "do you want to continue [y/N]? " answer
    if [[ "${answer}" != y ]] ;then
        log-info deploy "Stopping karmah"
        exit 1
    fi
    action_already_run[ask]=false # will be asked again if ask is run multiple times
}

action::deploy() {
    manifest_dir=deployed/manifests/$target_name
    local deploy_actions=$(add-commas ${deploy_actions:-render,git-diff,ask,git-commit})
    log-verbose deploy "deploy ${manifest_dir} with actions: ${deploy_actions}"
    git-add-message "deploy $target_name"
    # TODO: manifest_dir is different for actions before this action
    # should be first (only) action
    log-info deploy "deploying $target_name with actions ${deploy_actions// /,}"
    run-actions $deploy_actions # This is depends on karmah_type
}

action::plan() {
    local actions=$(add-commas ${plan_actions:-render,git-diff})
    log-info deploy "planning deploy $target_name with actions: ${actions// /,}"
    run-actions $actions
}

action::undeploy() {
    manifest_dir="${to_dir:-deployed/manifests}/${target_name}"
    local actions=$(add-commas ${undeploy_actions:-render-rm,git-diff,ask,git-commit})
    log-info deploy "undeploying ${target_name} with actions: ${actions}"
    run-actions $actions
}
