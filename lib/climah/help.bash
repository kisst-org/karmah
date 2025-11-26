init_climah_vars_help() {
    declare -g action_help=""
    declare -g command_help=""
    declare -g option_help=""
    declare -gA help_text=()
    declare -g help_level=basic
}

init_climah_module_help() {
    add_command aliases "show all defined aliases"
    add_command version "show version of karmah"
    add_option h help "" "show help information"
}

parse_option_help() { show_help; exit; }

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
  echo -n Options:
  for h in "${help_text[option,basic]}"; do printf "%s\n" "$h"; done
  if $(log_is_verbose); then
    echo -n "expert options:"
    for h in "${help_text[option,expert]}"; do printf "%s\n" "$h"; done
  fi

  echo -n Actions:
  for h in "${help_text[action,basic]}"; do printf "%s\n" "$h"; done
  if $(log_is_verbose); then
    echo -n "expert actions:"
    for h in "${help_text[action,expert]}"; do printf "%s\n" "$h"; done
  else
    echo show more verbose help using the following command
    echo "  karmah --verbose --help"
    echo "  karmah -v -h"
  fi
}


run_command_aliases() {
  echo Aliases:
  for key in $(printf "%s\n" ${!aliases[@]} | sort); do
      printf "  %-13s %s\n" $key "${aliases[$key]}"
  done |sort -k2 -k1
}

show_help_version() {
  echo karmah version: $karmah_version
}
