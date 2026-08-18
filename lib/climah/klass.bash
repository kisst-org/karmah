klass::declare-vars() {
    declare -gA klass_parent=()
}

init-parent-klass() {
  local parent=$1
  if [[ -z ${current_klass:-} ]]; then
    log-error klass "current_klass not defined when setting parent $parent"
    exit 1
  fi
  klass_parent[$current_klass]=$parent
  current_klass=$parent $parent::init-klass
}

kall-method() { kall-klass-method $current_klass "$@"; }
kall-klass-method() {
  local klass=$1 method=$2; shift 2
  local func=$(find-klass-method $klass $method)
  if [[ -z $func ]]; then
    log-error klass "could not find method $method in klass $klass to call with $*"
    exit 1
  fi
  $func "$@"
}
# call-parent-klass-method

find-klass-method() {
  local klass=$1 method=$2
  # current_klass???
  local kl=$klass
  while [[ ! -z $kl ]]; do
    if $(function-exists $kl::$method); then
      log-debug klass "calling klass method $kl::$method"
      echo $kl::$method
      return
    fi
    log-debug klass "not found $kl::$method"
    if [[ $kl == base ]]; then
      kl=""
    else
      kl=${klass_parent[$kl]:-base}
    fi
  done
}
