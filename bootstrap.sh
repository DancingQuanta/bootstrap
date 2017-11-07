#!/bin/sh
## DancingQuanta/bootstrap - https://github.com/DancingQuanta/bootstrap
## bootstrap.sh
## bootstrap.sh bootstraps new system

# To run this without copy/paste the whole thing:
# bash < <(curl -s https://raw.githubusercontent.com/DancingQuanta/bootstrap/master/bootstrap.sh)

## ---------------------------------------------------------------------------
## Variables
## ---------------------------------------------------------------------------
SELF="$(basename $0)"

## ---------------------------------------------------------------------------
## Functions
## ---------------------------------------------------------------------------
log() {
  # *log*: a wrapper of echo to print stuff in a more colorful way
  ECHO_ARGS=""
  test "$1" = "-n" && {
    ECHO_ARGS="-n"
    shift
  }
  echo $ECHO_ARGS "$(tput sgr0)$(tput setaf 2)>$(tput bold)>$(tput sgr0) $*"
}
warn() {
  # *warn*: a wrapper of echo to print stuff in a more colorful way, warning
  test "$1" = "-n" && {
    ECHO_ARGS="-n"
    shift
  }
  echo $ECHO_ARGS "$(tput sgr0)$(tput setaf 3)<$(tput bold)<$(tput sgr0) $*"
}
fatal () {
  # *fatal*: a wrapper of echo to print stuff in a more colorful way, error
  test "$1" = "-n" && {
    ECHO_ARGS="-n"
    shift
  }
  echo $ECHO_ARGS "$(tput sgr0)$(tput setaf 9)<$(tput bold)<$(tput sgr0) $*" >&2
  exit $2
}

runroot() {
  # if we don't have EUID variable and id doesn't exist, then we're going
  # to assume we're root
  euid=${EUID:-$(id -u 2>/dev/null || echo 0)}
  if [ "${euid}" = "0" ]; then
    eval "${*}"
  else
    hash sudo 2>/dev/null || \
      echo "you are not root and sudo is not installed. Please re-run as root"
    eval "sudo ${*}"
  fi
}
install_package() {
  pkgname=$1

  # This assumes the package name is the same on all package managers (big assumption)
  # and that sudo is on the system and user has sudo rights
  hash "${pkgname}" 2> /dev/null || \
    { hash apt-get 2> /dev/null && runroot apt-get install "${pkgname}"; }

  hash "${pkgname}" 2> /dev/null || \
    fatal "Could not install $pkgname on this system. Please fix and try again" 1
  unset pkgname
}
upgrade() {
  # Upgrade current packages
  hash apt-get 2> /dev/null && runroot apt-get update && runroot apt-get upgrade && runroot apt-get dist-upgrade
}
download() {
  cmd='curl -L "'"${1}"'" -o "'"${2}"'"'
  hash curl 2>/dev/null || \
    { hash wget 2>/dev/null && cmd='wget "'"${1}"'" -O "'"${2}"'"'; } || \
    install_package curl
  
  log "Downloading with: ${cmd}"
  eval "${cmd}"
  chmod a+x "${2}"
}

## ---------------------------------------------------------------------------
## Bootstrap
## ---------------------------------------------------------------------------

# Setup home bin 
[ -d "$HOMEBIN" ] || mkdir -p $HOMEBIN && log "Created $HOMEBIN"
# Append $HOMEBIN to PATH if directory exists and it is not yet in PATH
if [[ $UID -ge 1000 ]] && [[ -d $HOMEBIN ]] && [[ -z $(echo $PATH | grep -o $HOMEBIN) ]]; then
    export PATH=$HOMEBIN:$PATH
    log "added $HOMEBIN to path"
fi

###############################################################################
# Packages
###############################################################################

log "Upgrading packages"
upgrade

log "Installing packages"
if [[ -f $DIR/packages/packages ]]; then
  exec<$DIR/packages/packages
  while read line
  do
    if [[ ! "$line" =~ (^#|^$) ]]; then
      install_package install $line
    fi
  done
fi

###############################################################################
# python
###############################################################################

log "Installing python modules"
packages=
if [[ -f $DIR/packages/python ]]; then
  exec<$DIR/packages/python
  while read line
  do
    if [[ ! "$line" =~ (^#|^$) ]]; then
      packages="$packages $line"
    fi
  done
  pip install $packages
fi

###############################################################################
# Dotfiles
###############################################################################

log "Installing root vcsh repo"
bash < <(curl -s https://raw.githubusercontent.com/DancingQuanta/vcsh-config/bootstrap/bootstrap.sh)

log "Cloning vcsh repos"
if [[ -f $DIR/packages/vcsh ]]; then
  exec<$DIR/packages/vcsh
  while read line
  do
    if [[ ! "$line" =~ (^#|^$) ]]; then
      vcsh clone $line
    fi
  done
fi
