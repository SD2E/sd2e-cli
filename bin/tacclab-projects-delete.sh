#!/bin/bash
#
# tacclab projects delete

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# source ${DIR}/common.sh
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }


function usage() {

cat <<EOF
${ITME}: PROJECT [PROJECT...]

Delete a Gitlab project*

 Options:
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit

* Be careful - this is permanent and immediate!
EOF

}

interactive_opts=(name description path visibility tags)

gitlab_tenantid=${tenantid}
gitlabusername=$(get_gitlab_username)
projname=
projdesc=
projpath=
projns=${gitlabusername}
projvis="private"
projtags=

verbose=0
veryverbose=0
storetoken=1

urlencode() {
  # https://gist.github.com/cdown/1163649
  local LANG=C i c e=''
  for ((i=0;i<${#1};i++)); do
                c=${1:$i:1}
    [[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
                e+="$c"
  done
  echo "$e"
}

function main () {

    hosturl="$(get_gitlab_uri)/api/$(get_gitlab_api)/projects"

    for projpath in $args;
    do
      stderr "Deleting ${projpath}..."
      urlpath=$(urlencode $projpath)
      delpath="${hosturl}/${urlpath}"

      if ((veryverbose)); then
        cmd="curl -sk -XDELETE -H \"$(get_gitlab_auth_header)\" ${delpath}"
        out "Calling $cmd"
      fi

      response=$(curl -sk -XDELETE -H "$(get_gitlab_auth_header)" \
               ${delpath})

      result=$(jsonquery "$response" "message")
      if [[ ! "$result" =~ "202" ]]; then
        warning "  ${projpath}: $result"
      fi

    done

}

format_api_json() {

  echo "$1"

}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -z|--access_token) shift; gitlab_access_token="$1" ;;
    -v|--verbose) verbose=1 ;;
    -V|--veryverbose) veryverbose=1; verbose=1 ;;
    -i|--interactive) interactive=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

args="$@"

# Run the script logic
source "$DIR/tacclab-runner.sh"

main
