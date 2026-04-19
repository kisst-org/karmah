karmah-show-full-help() {
cat <<EOF
karmah: Kubernetes Application Rendered MAnifest Helper (version $karmah_version)

Description:
  karmah helps to enforce the rendered manifest pattern for targets
  Each target is defined in a karmah file, which defines various options, like:
  - rendering method to use (e.g. helm, kustomize)
  - rendering parameters, e.g. helm charts and value file
  - deployment method, e.g helm intstall, kapp deploy, kubectl apply
  - kubernetes info, e.g. kubeconfig, context and namespace
  - helper info, e.g. how to inspect, scale and change versions

Usage:
  ${climah_prog_name} [ option | command/flow | target ]...

$(show-short-help)

Targets:
  Each path defines an application definition, that will be sourced,
  This can either be a file, or a directory that contains exactly 1 file with a name '*.karmah'.
  When one or more --subdir's are specfied, these will be appended to the path.

Note:
  Options, commands/actions and paths can be mixed freely.
  If multiple commands are given, only last command will be used.
EOF
}
