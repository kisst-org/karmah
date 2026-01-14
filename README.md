# `karmah`: Kubernetes Application Rendering MAnifest Helper

The program `karmah` is a simple but flexible tool to render manifests for kubernetes.

The purpose is to render the manifests for a specific application (`appname`) and a specific environment.

# Render Definitions


# Running `karmah`
It can be run with the following options:

```
karmah [ option | command | action | path ]...

Options:
  h|--help                  show general help information
  X|--extended-help         show extensive help information
  v|--verbose               give more output
  q|--quiet                 show no output
  S|--show-script           show all commands without doing much
  C|--log-cmds              show the commands being executed
  n|--dry-run               do not execute the actual commands
  --debug                   show detailded debug info
  t|--to path               other path to render to (default is tmp/manifests)
  w|--with path             used for comparison between two manifest trees
  m|--message msg           set message to use with git commit
  --fixed-message msg       set fixed message to use with git commit
  M|--prepend-message msg   prepend commit message before auto generated message
  Q|--quiet-diff            do not show the output of diff
  y|--yes                   do not ask for confirmation (with ask, kapp-deploy, ...)
  H|--force-helm-chart chrt force to use a specific helm chart
  R|--replicas nr           specify number of replicas
  r|--resource res          specify a resource
  a|--add-actions act       add action to list of actions to perform
  A|--set-actions act       set the action to list of actions to perform
  F|--flow flw              use a (custom) flow named <flw>
  T|--tmp                   render to tmp/manifests, do not commit
  s|--subdir dir            add subdir to list of subdirs (can be comma separated list)
  K|--force-karmah-type typ force to use another karmah_type
  V|--version ver           specify version (tag) to use for update or scale
  u|--update expr           apply a custom update
Commands:
  help          show general help (h)
  options       show available options
  run-actions   run actions forall targets (run)
  actions       show available actions
Actions:
  render        update render manifests to --to <path> (default tmp/manifests) (r)
  compare       render manifests to --to <path> (default tmp/manifests) and then compare with --with path (default deployed/manifests)
  render-rm     remove all rendered manifests (rm)
  git-diff      shows the changes to source and rendered manifests with git (gd)
  git-add       adds the changes to source and rendered manifests to git, for committing (ga)
  git-commit    commits the changes to source and rendered manifests to git (gc)
  git-restore   restores the changed files (source and rendered manifests) (gr)
  deploy        render to deployed/manifests and optionally deploy to kubernetes
  plan          show what deploy action would do
  ask           ask for confirmation (unless --yes is specified) (no-cmd)
  helm-diff     run helm diff plugin for target (hD)
  helm-upgrade  run helm upgrade --install for target
  helm-install  deprecated: run helm upgrade --install for target
  helm-uninstall run helm uninstall for target
  helm-get-manifests download helm manifests from cluster
  helm-get-diff run diff for target vs helm deployed manifests (hd)
  kapp-plan     show what resources will be updated
  kapp-diff     show what resources will be updated, including detailed diffs
  kapp-deploy   deploy the application with kapp
  kapp-delete   delete the application with kapp
  kube-diff     compare rendered manifests with cluster (kubectl diff) (kd)
  kube-apply    apply rendered manifests with cluster (kubectl apply) (ka)
  kube-delete   delete all manifests from cluster (kubectl delete)
  kube-watch    watch target resources every 2 seconds (kw)
  kube-get      get current manifests from cluster to --to <path> (default) deployed/manifests
  kube-diff-del show resources that will be deleted with kube-delete
  kube-tmp-scale scale resource(s) without changing source or deployment files
  kube-restart  restart resource(s)
  kubectl       generic kubectl in the right cluster and namespace of all targets (k)
  kube-status   show status of relevant resources (ks)
  kube-exec     execute a command on a pod of a resource (ke)
  kube-exec-it  execute interactive command on a pod of a resource add-action kei kube-exec-it execute interactive command on a pod of a resource (kei)
  kube-log      show logging of a resource (kl)
  update        update source files with expressions from --update (u)
Paths:
  Each path defines an application definition, that will be sourced,
  This can either be a file, or a directory that contains exactly 1 file with a name '*.karmah'.
  When one or more --subdirs are specfied, these will be append to the path

Note:
  Options, commands, actions and paths can be mixed freely
  If multiple commands are given, only last command will be used
```

# Installation
The only requirement is to have a recent version of `bash` available.

Additionally the following tools are needed for some commands:
- `helm`: for rendering helm templates
- `yq`: is needed for splitting the output of `helm template` to individual files
- `git`: for the `pull` and `commit` commands
- `kubectl`: with a correct kubeconfig file for the `diff` and `apply`
- `kapp`: if this functionality is used

Installation can be done by copying the `karmah` script to the correct location.
```
curl -OL https://raw.githubusercontent.com/kisst-org/karmah/refs/heads/main/karmah
chmod 755 karmah
```
No further file need to be downloaded

# Directory structure
The script can be placed in the directory with all the manifests definitions.

The following directory structure is recommended when using `helm` as renderer:
- `karmah`: the script itself
- `apps/<appname>/<env>/render-app-<appname>-<env>.karmah`: render-definitions for an application and environment
- `apps/<appname>/<env>/values-app-<appname>-<env>.yaml`:  helm values file for an environment of an application
- `apps/<appname>/common/values-<appname>.yaml`: helm values file for all environments of an application
- `helm/charts`: the helm-charts that can be referred to in the render definitions
- `helm/env-value-files/values-<env>.karmah`: values specific for this environment
- `tmp/manifests`: the location where the rendered manifests are stored
- `deployed/manifests`: the location to store rendered manifests that are actually are deployed
- `config.d`: specific configuration, e.g. kubenertes details or aliasses
