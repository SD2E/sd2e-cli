#!/bin/bash
#
# tacclab groups list

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# source ${DIR}/common.sh
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

function usage() {

cat <<EOF
${ITME}: [OPTION]...

List Gitlab groups for the current user

 Options:
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
EOF

}

interactive_opts=()

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

    hosturl="$(get_gitlab_uri)/api/$(get_gitlab_api)/groups?all_available=true"

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
      paths=($(jsonquery "$1" ".[].path"))
      #names=($(jsonquery "$1" ".[].name"))
      #descs=($(jsonquery "$1" ".[].description"))
      ids=($(jsonquery "$1" ".[].id"))
      n=0
      echo -e "Group\tID\n=====\t=="
      for i in "${paths[@]}"; do
        echo -e "${i}\t${ids[$n]}"
        n=$[n+1]
      done
  fi
}

# format_api_json() {

#   if ((veryverbose)); then
#     echo "$1"
#   elif [[ $verbose -eq 1 ]]; then
#     json_prettyify "$1"
#   else
#       titles=($(jsonquery "$1" ".[].title"))
#       creates=($(jsonquery "$1" ".[].created_at"))
#       ids=($(jsonquery "$1" ".[].id"))
#       n=0
#       for i in "${titles[@]}"; do
#         echo -e "${ids[$n]}\t${i}\t${creates[$n]}"
#         n=$[n+1]
#       done
#   fi
# }

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
    -i|--interactive) interactive=0 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

args=("$@")

# Run the script logic
source "$DIR/tacclab-runner.sh"

main
