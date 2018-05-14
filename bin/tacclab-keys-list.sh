#!/bin/bash
#
# tacclab keys list - list users SSH public keys

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

List SSH keys for the current Gitlab user.

 Options:
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
EOF

}

interactive_opts=(name description path visibility tags)

gitlab_tenantid=${tenantid}
gitlabusername=$(get_gitlab_username)
limit=50
skip=0
sortkey="path"
sortorder="asc"
verbose=0
veryverbose=0
storetoken=1

function main () {

    hosturl="$(get_gitlab_uri)/api/$(get_gitlab_api)/user/keys"

    if ((veryverbose)); then
      cmd="curl -sk -X GET -H \"$(get_gitlab_auth_header)\" ${hosturl}"
      out "Calling $cmd"
    fi

    response=`curl -sk -X GET -H "$(get_gitlab_auth_header)" ${hosturl}`

    if [ ! -z "$(jsonquery "$response" ".[].id")" ]; then
      result=$(format_api_json "$response")
      echo -n "$result"
    else
      die "No keys found for current user"
    fi

}

format_api_json() {

  if ((veryverbose)); then
    echo "$1"
  elif [[ $verbose -eq 1 ]]; then
    json_prettyify "$1"
  else
      titles=($(jsonquery "$1" ".[].title"))
      creates=($(jsonquery "$1" ".[].created_at"))
      ids=($(jsonquery "$1" ".[].id"))
      n=0
      echo -e "ID\tTitle\tCreated\n==\t=====\t======="
      for i in "${titles[@]}"; do
        echo -e "${ids[$n]}\t${i}\t${creates[$n]}"
        n=$[n+1]
      done
  fi
}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -z|--access_token) shift; gitlab_access_token="$1" ;;
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
