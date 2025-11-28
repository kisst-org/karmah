init_climah_vars_help() {
    declare -g help_level=basic
    declare -g all_help_topics=""
    declare -gA help_topic_function=()
    declare -gA help_topic_module=()
    declare -gA help_topic_short=()
    declare -gA help_topic_level=()
    declare -gA help_topic_alias=()
    declare -gA help_topic_help=()

}

init_climah_module_help() {
    add-command h  help show-help  "show general help"
    add-option  h  help ""         "show general help information"

    add-help-subject al  aliases  show-aliases "show all defined aliases"
    add-help-subject ver version  show-version "show version of karmah"
    add-help-subject mod modules  show-modules "show all modules"
    add-help-subject top topics   show-help-topics "show all help-topics"

    parse_arg_func[help]=parse-option-help
}

add-help-subject() {
    local short=$1
    local name=$2
    local func=${3:-show-$name}
    shift 3
    local help=$@
    #parse_arg_func[$name]=parse-command
    if [[ ${enable_short_commands:-true} && ! -z $short ]]; then
        local s
        for s in ${short//,/ }; do
            #parse_arg_func[$s]=parse-command
            help_topic_alias[$s]=$name
        done
        help+=" ($short)"
    fi
    help_topic_function[$name]=$func
    help_topic_module[$name]=$module
    help_topic_help[$name]=$help
    help_topic_short[$name]=$short
    help_topic_level[$name]=$help_level
    all_help_topics+=" $name"
}

parse-option-help() { collect_unknown_args=true;  command=help;  }

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

show-help() {
    local found=false
    for arg in $extra_args; do
        arg=${help_topic_alias[$arg]:-$arg}
        if [[ ! -z ${help_topic_function[$arg]:-} ]] ; then
            ${help_topic_function[$arg]}
            found=true
        else
          warn unknown help topic $arg
          show-help-topics
          exit 1
        fi
    done
    if ! $found; then
        show_short_help
    fi
}

show_full_help() {
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

show-help-topics() {
    local topic
    for topic in $all_help_topics; do
        printf "karmah help %-13s    # %s\n" $topic "${help_topic_help[$topic]}"
    done #|sort -k2 -k1
}
