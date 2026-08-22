klass::declare-vars() {
    declare -gA klass_parent=()
}

declare-parent-klass() {
  local parent=$1
  if [[ -z ${current_klass:-} ]]; then
    log-error klass "current_klass not defined when setting parent $parent"
    exit 1
  fi
  klass_parent[$current_klass]=$parent
}

init-parent-klass() {
  local parent=$1
  declare-parent-klass $parent
  log-trace klass "init klass $parent"
  if $(function-exists $parent::init-klass); then
      current_klass=$parent $parent::init-klass
  fi
}

kall-method() { kall-klass-method $current_klass "$@"; }
kall-klass-method() {
  local klass=$1 method=$2; shift 2
  local func=$(find-klass-method $klass $method)
  if [[ -z $func ]]; then
    log-error klass "could not call method $klass::$method $*"
    exit 1
  fi
  log-debug klass "kalling klass method $func $*"
  $func "$@"
}
# call-parent-klass-method

find-klass-method() {
  local klass=$1 method=$2
  # current_klass???
  local kl=$klass
  while [[ ! -z $kl ]]; do
    if $(function-exists $kl::$method); then
      log-trace klass "found klass method $kl::$method"
      echo $kl::$method
      return
    fi
    log-trace klass "no klass method $kl::$method"
    if [[ $kl == base ]]; then
      kl=""
    else
      kl=${klass_parent[$kl]:-base}
    fi
  done
}
