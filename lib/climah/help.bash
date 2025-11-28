init_climah_vars_help() {
    declare -g command_help=""
    declare -g option_help=""
    declare -gA help_text=()
    declare -g help_level=basic
}

init_climah_module_help() {
    add-command h   help     show_help    "show general help"
    add-command al  aliases  show-aliases "show all defined aliases"
    add-command ver version  show-version "show version of karmah"

    add-option h help "" "show general help information"
}

parse-option-help() { show_help; exit; }

add-help() {
  local section=$1
  local name=$2
  local option=$3
  shift 3
  help_text[$help_level,$section,$module,$name]+="${@}"
}


add_help_text() {
  local section=$1
  shift
  help_text[$section,$help_level]+="${@}"
}

show_help() {
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
  karmah [ option | action | target ]...

EOF
show_short_help
cat <<EOF
Targets:
  Each path defines an application definition, that will be sourced,
  This can either be a file, or a directory that contains exactly 1 file with a name '*.karmah'.
  When one or more --subdirs are specfied, these will be append to the path

Note:
  If multiple commands are given, only last command will be used
EOF
}

show_short_help() {
  echo Options:
  show-options
  echo
  echo Commands:
  show-commands
  if [[ ${level:-basic} == all ]]; then
    echo
    echo Actions:
    show-actions
  fi
}

show-aliases() {
  echo Aliases:
  for key in $(printf "%s\n" ${!aliases[@]} | sort); do
      printf "  %-14s %s\n" $key "${aliases[$key]}"
  done |sort -k2 -k1
}

show-version() {
  echo karmah version: $karmah_version
}
