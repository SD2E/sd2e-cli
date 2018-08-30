#!/bin/bash
#
# tacclab projects list - list projects user has access to

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

List projects to which the current user has access

 Options:
  -q, --query           Plain-text query for name or path
  -l, --limit           Maximum number of results to return
  -o, --offset          Number of results to skip from start
  -s, --sort            Sort by id, name, path, [created_at]
      --asc             Sort in ascending order [default]
      --desc            Sort in descending order
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
EOF

}

interactive_opts=()

gitlab_tenantid=$(get_agave_tenant)
gitlabusername=$(get_gitlab_username)
limit=50
skip=0
sortkey="path"
sortorder="asc"
verbose=0
veryverbose=0
storetoken=1

function main () {

    hosturl="$(get_gitlab_uri)/api/$(get_gitlab_api)/projects"

    page=$(( $skip / $limit ))
    page=$(( $page + 1 ))

    if [ "$sortkey" != "id" ] && [ "$sortkey" != "name" ] && [ "$sortkey" != "path" ] && [ "$sortkey" != "created_at" ]; then
      sortkey="created_at"
    fi

    response=`curl -sk -G -H "$(get_gitlab_auth_header)" \
               --data-urlencode search="${query}" \
               "${hosturl}?simple=true&per_page=${limit}&page=${page}&order_by=${sortkey}&sort=${sortorder}"`

    if [ ! -z "$(jsonquery "$response" ".[].id")" ]; then
      result=$(format_api_json "$response")
      success "$result"
    else
      stderr "No projects found matching $query"
    fi

}

format_api_json() {

  if ((veryverbose)); then
    echo "$1"
  elif [[ $verbose -eq 1 ]]; then
    json_prettyify "$1"
  else
    project_paths=$(jsonquery "$1" ".[].path_with_namespace")
    echo -e "Projects\n========\n$project_paths"
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
    -q|--query) shift; query="$1" ;;
    -s|--sort) shift; sortkey="$1" ;;
       --asc) sortorder="asc" ;;
       --desc) sortorder="desc" ;;
    -l|--limit) shift; limit=$1 ;;
    -o|--offset) shift; skip=$1 ;;
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
