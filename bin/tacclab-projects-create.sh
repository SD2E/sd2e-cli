#!/bin/bash
#
# tacclab projects create - create a Gitlab project

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

Create a new Gitlab repository.

 Options:
  -n, --name            Repository name for new project
  -d, --description     Free-text project description
  -b, --visibility      Visibility (public, internal, [private])
  -g, --group           Gitlab namespace [$(get_gitlab_username)]
  -o, --open            Open browser to URL of new repository
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
EOF

}

interactive_opts=(name description visibility)

gitlab_tenantid=${tenantid}
gitlabusername=$(get_gitlab_username)
projname=
projdesc=
projpath=
projgrp=
projvis="private"
projtags=
projurl=
interactive=0

verbose=0
veryverbose=0
storetoken=1
openurl=0

function lookup_group_id() {

  groupname="$1"
  groupid=
  if [[ "${groupname}" != "${gitlabusername}" ]]; then
    response=$(${DIR}/tacclab groups list -v)
    groupid=$(echo "${response}" | jq -r ".[] | select(.path==\"$groupname\").id")
  fi
  echo ${groupid}
}

function main () {

    hosturl="$(get_gitlab_uri)/api/$(get_gitlab_api)/projects"
    if [ -z "$projname" ]; then
      err "You must specify --name when creating a project"
    fi
    if [ "$projvis" != "public" ] && [ "$projvis" != "internal" ] && [ "$projvis" != "private" ]; then
      err "Only public, internal, and private are allowed settings for project visibility"
    fi
    if [[ ! -z "${projgrp}" ]] && [[ "${projgrp}" != "${gitlabusername}" ]]; then
      projns=$(lookup_group_id $projgrp)
      if [ -z "$projns" ]; then
        err "Invalid group: $projgrp"
      fi
    fi

    response=`curl -sk -XPOST -H "$(get_gitlab_auth_header)" \
               -d path="$projname" \
               -d namespace_id="$projns" \
               -d description="$projdesc" \
               -d visibility="$projvis" \
               -d issues_enabled=true \
               -d merge_requests_enabled=true \
               -d snippets_enabled=true \
               -d jobs_enabled=true \
               ${hosturl}`

    #if [ $(jsonquery "$response" "id")  != "null" ]; then
    pid=$(jsonquery "$response" "id")
    if [ ! -z "$pid" ] && [ "$pid" != "null" ]; then
     result=$(format_api_json "$response")
     out "${result}"
    else
      err "${response}"
    fi

}

format_api_json() {

  if ((veryverbose)); then
    echo "$1"
  elif ((verbose)); then
    json_prettyify "$1"
  else
    proj_name=$(jsonquery "$1" "name")
    proj_path=$(jsonquery "$1" "path_with_namespace")
    proj_url=$(jsonquery "$1" "web_url")
    proj_ssh_url=$(jsonquery "$1" "ssh_url_to_repo")
    proj_vis=$(jsonquery "$1" "visibility")
    proj_sum="\n  Name: ${proj_name}\n  Path: ${proj_path}\n"
    proj_sum="${proj_sum}  Visibility: ${proj_vis}\n  URL: ${proj_url}\n  SSH: ${proj_ssh_url}"
    echo "Created Gitlab project. $proj_sum"
    if ((openurl)); then
       open_url "${proj_url}"
       stderr ${proj_url}
    fi
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
    -n|--name|-p|--path) shift; projname="$1" ;;
    -d|--description) shift; projdesc="$1" ;;
    -g|--group) shift; projgrp="$1" ;;
    -b|--visbility) shift; projvis="$1" ;;
    -t|--tags) shift; tags="[$1]" ;;
    -o|--open) shift; openurl=1 ;;
    -v|--verbose) verbose=1 ;;
    -V|--veryverbose) veryverbose=1; verbose=1 ;;
    -i|--interactive) interactive=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

args=("$@")

function prompt_options() {
    # Overrides tacclab-common.sh
    local currentconfig=$(kvget $TACCLAB_CACHE_DIR ${GITLAB_STORE})

    for val in ${interactive_opts[@]}; do
      if [[ $val == "name" ]]; then
        echo -n "Project name: "; read projnamein
        projname="${projnamein}"
        if [ -z "$projname" ]; then
          die "The project must have a name."
        fi
      elif [[ $val == "description" ]]; then
        echo -n "Project description: "; read projdescin
        projdesc="${projdescin}"
      elif [[ $val == "visibility" ]]; then
        savedprojvis="private"
        echo -n "Project visibility [$savedprojvis]: "; read projvisin
        if [ -z "$projvisin" ]; then
          projvis="${savedprojvis}"
        else
          projvis="${projvisin}"
        fi
      fi
    done

}

# Run the script logic
source "$DIR/tacclab-runner.sh"

main
