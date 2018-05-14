#!/bin/bash
#
# tacclab keys remove - dlete an SSH key from the user's Gitlab profile

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

function usage() {

cat <<EOF
${ITME}: [OPTION] ID [ID... ]

Remove an SSH public key from the current Gitlab user profile.

 Options:
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
EOF

}

interactive_opts=(name description path visibility tags)

gitlab_tenantid=${tenantid}
gitlabusername=$(get_gitlab_username)
title=
key=
keyfile=
verbose=0
veryverbose=0
storetoken=1

function main () {

    hosturl="$(get_gitlab_uri)/api/$(get_gitlab_api)/user/keys"

    for keyid in $args;
    do

      if ((veryverbose)); then
        cmd="curl -sk -XDELETE -H \"$(get_gitlab_auth_header)\" ${hosturl}/${keyid}"
        out "Calling ${cmd}"
      fi
      response=`curl -sk -XDELETE -H "$(get_gitlab_auth_header)" \
                ${hosturl}/${keyid}`


      msg="Deleted"
      if [ ! -z "$response" ]; then
        msg=$(jsonquery "$response" "message")
      fi
      out "key: ${keyid} status: ${msg}"

      # kid=$(jsonquery "$response" "id")
      # if [ ! -z "$kid" ] && [ "$kid" != "null" ]; then
      #  result=$(format_api_json "$response")
      #  success "${result}"
      # else
      #   err "Error: $response"
      # fi

    done
}

format_api_json() {

  if ((veryverbose)); then
    echo "$1"
  elif [[ $verbose -eq 1 ]]; then
    json_prettyify "$1"
  else
    keyid=`jq -r .id <<< $1`
    keytitle=`jq -r .title <<< $1`
    keyval=`jq -r .key <<< $1`
    keyexcerpt="${keyval:0:19}... ${keyval:(-20)}"
    echo -n "${keyid}\t${keytitle}\t\"${keyexcerpt}\""
  fi
}

function serialize_pub_key() {
  echo -n $(echo ${1} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
}

function fingerprint_pub_key_file() {
  retval=1
  if ((haskeygen)); then
    fp=`ssh-keygen -E md5 -lf $1 | awk '{ print $2 }' | cut -c 5-`
    if [ "$?" == 0 ];then
      stderr "Fingerprint: ${fp}"
    else
      retval=0
    fi
  fi
  echo ${retval}
}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -z|--access_token) shift; gitlab_access_token="$1" ;;
    -h|--help|help) usage >&2; safe_exit ;;
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
