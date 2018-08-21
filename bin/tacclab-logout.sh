#!/bin/bash
#
# tacclab logout : invalidates the current access/refresh token pair

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

function usage() {

cat <<EOF
${ITME}: [OPTION]...

Log out of the tenant default Gitlab server.

 Options:
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
      --version         Output version information and exit
EOF

}

interactive_opts=()

gitlab_tenantid=$(get_agave_tenant)
gitlabusername=$(get_gitlab_username)
gitlaburl=
interactive=0
verbose=0
veryverbose=0

function main () {

    hosturl="$(get_gitlab_uri)"

    if ((veryverbose)); then
        [ "$piped" -eq 0 ] && log "Logging out of ${hosturl}..."
    fi

    kvset $TACCLAB_CACHE_DIR $GITLAB_STORE "{\"tenantid\":\"$gitlab_tenantid\",\"baseurl\":\"$(get_gitlab_uri)\",\"devurl\":\"$devurl\",\"username\":\"${gitlabusername}\",\"access_token\":\"\",\"refresh_token\":\"\",\"created_at\":\"\",\"expires_in\":\"\",\"expires_at\":\"\"}"

    if [ "$?" == 0 ]; then
      success "Logged out"
    else
      err "Failed to log out"
    fi

}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -v|--verbose) verbose=1 ;;
    -V|--veryverbose) veryverbose=1; verbose=1 ;;
    -i|--interactive) interactive=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

args=("$@")

# Run the script logic
source "$DIR/tacclab-runner.sh"

main
