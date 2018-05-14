#!/bin/bash
#
# tacclab keys add - add an SSH key to the user's Gitlab profile

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

Add an SSH public key to the current Gitlab user profile.

 Options:
  -t, --title           Key title
  -k, --key             SSH public key passed via command line
  -F, --file            Path to a valid SSH public key file
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
EOF

}

interactive_opts=(title keyfile)

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

    if [ -z "${key}" ] && [ -z "${keyfile}" ]; then
      err "Either --key or --file must be specified"
    fi

    if [ ! -z "${keyfile}" ] && [ -f "${keyfile}" ];
    then

      fpvalid=$(fingerprint_pub_key_file ${keyfile})
      if ((! fpvalid)); then
        err "File ${keyfile} does not appear to be a valid key"
      else
        key=$(cat ${keyfile})
      fi
    fi

    if [ ! -z "${key}" ]; then
      key=$(serialize_pub_key "${key}")
    fi

    if [ -z "${title}" ]; then
      source $DIR/libs/petname.sh
      title=$(petname 3)
      stderr "No title provided. Key will be named \"${title}\""
    fi

    if ((veryverbose)); then
      cmd="curl -sk -X POST -H \"$(get_gitlab_auth_header)\" --data-urlencode title=\"${title}\" --data-urlencode key=\"XXXXXXXXXXXXXXXXXX\" ${hosturl}"
      out "Calling ${cmd}"
    fi
    response=`curl -sk -X POST -H "$(get_gitlab_auth_header)" \
              --data-urlencode title="${title}" \
              --data-urlencode key="${key}" ${hosturl}`

    kid=$(jsonquery "$response" "id")
    if [ ! -z "$kid" ] && [ "$kid" != "null" ]; then
     result=$(format_api_json "$response")
     success "${result}"
    else
      err "$response"
    fi

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
    -t|--title) shift; title="$1" ;;
    -k|--key) shift; key="$1" ;;
    -F|--file) shift; keyfile="$1" ;;
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
    local currentconfig=$(tacc.kvget ${GITLAB_STORE})

    for val in ${interactive_opts[@]}; do
      if [[ $val == "title" ]]; then
        echo -n "Title for this SSH key: "; read title
        if [ -z "$title" ]; then
          source $DIR/libs/petname.sh
          title=$(petname 3)
          stderr "Title cannot be empty. Key will be named \"${title}\""
        fi
      elif [[ $val == "keyfile" ]]; then
        if [ -f ${HOME}/.ssh/id_rsa.pub ]; then
          defaultkeyfile=" [\$HOME/.ssh/id_rsa.pub]"
          hasdefaultkey=1
        fi
        echo -n "Path to SSH public key${defaultkeyfile}: "; read keyfilein
        if [ -z "${keyfilein}" ] && ((hasdefaultkey)); then
          keyfile="${HOME}/.ssh/id_rsa.pub"
        else
          keyfile="${keyfilein}"
        fi
        if [[ ! -f "${keyfile}" ]]; then
          die "Cannot locate file: ${keyfile}"
        fi
      fi
    done

}

# Run the script logic
source "$DIR/tacclab-runner.sh"

main
