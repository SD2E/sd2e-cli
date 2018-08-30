#!/bin/bash
#
# taccreg logout : invalidates the current credential cache

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

source ${DIR}/cli-common.sh
source ${DIR}/taccreg-common.sh

function usage() {

cat <<EOF
${ITME}: [OPTION]...

Log out of the tenant default Docker registry.

 Options:
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
      --version         Output version information and exit
EOF

}

interactive_opts=()

registry_tenantid=$(get_agave_tenant)
registryuser=
registrypassword=
registryuri=
verbose=0
veryverbose=0
storetoken=1

function main () {

    if ((veryverbose)); then
        [ "$piped" -eq 0 ] && log "Logging out..."
    fi

    registry_logout

    if [ "$?" != 0 ]; then
      err "Failed to log out."
    fi

}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -i|--interactive) interactive=0 ;;
    -h|--help) usage >&2; safe_exit ;;
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
source "${DIR}/taccreg-runner.sh"

main
