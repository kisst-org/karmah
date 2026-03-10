init_climah_vars_help() {
    declare -g help_level=basic
    declare -gA help_topic_function=()
    declare -gA help_topic_alias=()

    declare -gA help_item_summary=()
    declare -gA help_item_module=()
    declare -gA help_item_level=()
    declare -gA help_item_type=()
    declare -gA help_item_short=()
    declare -gA help_item_params=()
    declare -gA help_all_items=()
}

init_climah_module_help() {
    add-command h  help show-help    "show general help"
    add-option  h  help ""           "show general help information"
    add-option  X  extended-help ""  "show extensive help information"

    help-add-topic al  aliases  show-aliases "show all defined aliases"
    help-add-topic ver version  show-version "show version of karmah"
    help-add-topic mod modules  show-modules "show all modules"
    help-add-topic top topics   show-help-topics "show all help-topics"
    parse_arg_func[help]=parse-option-help
}

help-add-topic() {
    local short=$1 name=$2 func=${3} summary=${4:-no summary}
    help_topic_function[$name]=${func:-$name-show-help}
    if [[ ! -z $short ]]; then  help_topic_alias[$short]=$name; fi
    help-add-item topic "$short" $name "" "$summary"
}

help-add-item() {
    local type=$1 short=$2 name=$3 params=$4 summary=$5
    help_item_module[$name]=$module
    help_item_level[$name]=$help_level
    help_item_short[$name]=$short
    help_item_params[$name]=$params
    help_item_summary[$name]=$summary
    help_all_items[$type]+=" $name"
    # TODO local head="--$opt ${option_arg[$opt]}"
}

help-is-visible() {
    local lvl=$1
    local mod=$2
    if [[ ${help_show_module:-$mod} != $mod ]]; then
        echo false
    elif [[ ${help_show_level:-basic} == *${lvl}* || ${help_show_level:-basic} == all ]]; then
        echo true
    else
        echo false
    fi
}

help-list-items() {
    local type=$1
    local item len=1 slen=0
    for item in ${help_all_items[$type]}; do
        if $(help-is-visible ${help_item_level[$item]} ${help_item_module[$item]}); then
            local lname="$item ${help_item_params[$item]}"
            if (( $len < ${#lname} )); then len=${#lname}; fi
            local shortlen=${#help_item_short[$item]}
            if (( $slen < $shortlen)); then slen=$shortlen; fi
        fi
    done

    for item in ${help_all_items[$type]}; do
        local lname="$item ${help_item_params[$item]}"
        if $(help-is-visible ${help_item_level[$item]} ${help_item_module[$item]}); then
            printf "  %-${slen}s %-${len}s %s\n" "${help_item_short[$item]}" "$lname" "${help_item_summary[$item]}"
        fi
    done
}

parse-option-help() { collect_unknown_args=true;  command=help;  }
parse-option-extended-help() { help_show_level=all;  }


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

help-show-module() {
    help_show_module=$1
    help_show_level=all
    echo ${module_help[$help_show_module]}
    show-commands
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
        if [[ ${help_show_level:-} == all ]]; then
            show_full_help
        else
            show_short_help
        fi
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
  ${climah_prog_name} [ option | command | target ]...

EOF
show_short_help
cat <<EOF
Targets:
  Each path defines an application definition, that will be sourced,
  This can either be a file, or a directory that contains exactly 1 file with a name '*.karmah'.
  When one or more --subdirs are specfied, these will be append to the path

Note:
  Options, commands and paths can be mixed freely.
  If multiple commands are given, only last command will be used.
EOF
}

show_short_help() {
  echo Options:
  show-options
  echo
  echo Commands:
  show-commands
  echo
  echo see additional help topics with
  echo "   ${climah_prog_name} help topics"
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
cat <<EOF
${climah_prog_name} help [<topic>]

topic can be any of:
EOF
    help-list-items topic;
}
