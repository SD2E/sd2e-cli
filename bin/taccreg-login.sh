#!/bin/bash
#
# tacclab login

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

source ${DIR}/cli-common.sh
source ${DIR}/taccreg-common.sh

function usage() {

_maskedpass=$(maskpass "${registrypass}")

cat <<EOF
${ITME}: [OPTION]...

Log into the tenant default Docker registry (and cache the resulting token).

 Options:
  -U, --username        Docker Hub username [${registryuser}]
  -P, --password        Docker Hub password [${_maskedpass}]
  -O, --organization    Docker Hub organization* [${registryorg}]
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
      --version         Output version information and exit

* Entirely optional

EOF

}

interactive_opts=(username password organization)

registry_tenantid=$(get_agave_tenant)
registryuser=$(get_registry_user)
registrypass=$(get_registry_pass)
registryorg=$(get_registry_org)
registryuri=
interactive=1
verbose=0
veryverbose=0
storetoken=1

function main () {


    if ((veryverbose)); then
        [ "$piped" -eq 0 ] && log "Logging in..."
    fi

    registry_login

    if [ "$?" != 0 ]; then
      err "Failed to log in."
    fi

}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -i|--interactive) interactive=1 ;;
    -U|--username) shift; registryuser=$1 ;;
    -P|--password) shift; registrypass=$1 ;;
    -O|--organization) shift; registryorg=$1 ;;
    -v|--verbose) verbose=1 ;;
    -V|--veryverbose) veryverbose=1; verbose=1 ;;
    --version) version ; safe_exit ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

args=("$@")

# Run the script logic
stderr "Log into Docker Registry:"
source "$DIR/taccreg-runner.sh"

main
