#!/bin/bash
#
# tacclab login

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

Log into the tenant default Gitlab server and cache the resulting token.

 Options:
  -U, --username        Gitlab username [$(get_gitlab_username)]
  -P, --password        Gitlab password
  -q, --quiet           Supress output
      --force           Ignore existing token and log in
  -v, --verbose         Verbose output
  -V, --veryverbose     Very verbose output
  -h, --help            Display this help and exit
      --version         Output version information and exit

EOF

}

interactive_opts=(username password)

gitlab_tenantid=$(get_agave_tenant)
gitlabusername=$(get_gitlab_username)
gitlabpassword=
gitlaburl=
quiet=0
force=0
verbose=0
veryverbose=0
storetoken=1

function main () {

    out "Log into TACC.cloud Gitlab:"
    hosturl="$(get_gitlab_uri)/oauth/token"

    cmd="curl -s -XPOST -d \"grant_type=password\" -d \"username=${gitlabusername}\" -d \"password=XXXXXXXXX\" ${hosturl}"
    if ((veryverbose)); then
        [ "$piped" -eq 0 ] && log "Calling ${cmd}"
    fi

    response=`curl -s -XPOST -d "grant_type=password" -d "username=${gitlabusername}" -d "password=${gitlabpassword}" ${hosturl}`

    if [[ $(jsonquery "$response" "token_type") = 'bearer' ]]; then
        result=$(format_api_json "$response")
        out "$result"
    else
        err "$response"
    fi

}

format_api_json() {

    if ((storetoken)); then

        jsonval gitlab_access_token "$1" "access_token"
        jsonval gitlab_refresh_token "$1" "refresh_token"
        jsonval scope "$1" "scope"
        expires_in=${GITLAB_TOKEN_TTL}

        created_at=$(date +%s)

        if date --version >/dev/null 2>&1 ; then
          expires_at=`date -d @$(expr $created_at + $expires_in)`
        else
          expires_at=`date -r $(expr $created_at + $expires_in)`
        fi

        tacc.kvset $GITLAB_STORE "{\"tenantid\":\"$tenantid\",\"baseurl\":\"$(get_gitlab_uri)\",\"devurl\":\"$devurl\",\"username\":\"$gitlabusername\",\"access_token\":\"$gitlab_access_token\",\"refresh_token\":\"$gitlab_refresh_token\",\"created_at\":\"$created_at\",\"expires_in\":\"$expires_in\",\"expires_at\":\"$expires_at\"}"
        stderr "Gitlab token for ${gitlab_tenantid}:${gitlabusername} stored";
    fi

    if ((veryverbose)); then
        out "${1}"
    elif [[ $verbose -eq 1 ]]; then
        json_prettyify "${1}"
    else
        result=$(jsonquery "$1" "access_token")
        echo "${result}"
    fi
}

# Handle arguments
source "$DIR/options.sh"
[[ $# -eq 0 ]] && set -- "-i"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -q|--quiet) quiet=1 ;;
    --force) force=1 ;;
    -U|--username) shift; gitlabusername=$1 ;;
    -P|--password) shift; gitlabpassword=$1 ;;
    -L|--url) shift; gitlaburl=$1 ;;
    -v|--verbose) verbose=1 ;;
    -V|--veryverbose) veryverbose=1; verbose=1 ;;
    -i|--interactive) interactive=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

args=("$@")

# if [ "$gitlab_disable_cache" -ne 1 ] && [ -z "$gitlab_access_token" ]; then # user did not specify an gitlab_access_token as an argument
#     tokenstore=$(tacc.kvget ${GITLAB_STORE})
#     if [ -n "$tokenstore" ]; then
#         jsonval gitlabusername "${tokenstore}" "username"
#         jsonval gitlab_access_token "${tokenstore}" "access_token"
#         jsonval gitlab_refresh_token "${tokenstore}" "refresh_token"
#         # Mechanism to auto-refresh expired bearer tokens
#         if [ -n "$gitlab_refresh_token" ]; then
#             token_life_remaining=$(get_token_remaining_time ${GITLAB_STORE})
#             tacclab_refreshed_ok=1 # assume refresh is OK - this is set to zero in auto_auth_refresh
#             if [ ${token_life_remaining}  -lt  60 ]; then
#                 stderr "Gitlab token has expired. Refreshing..."
#                 gitlab_auto_auth_refresh
#                 jsonval gitlab_access_token "$(tacc.kvget ${GITLAB_STORE})" "access_token"
#                 jsonval gitlab_refresh_token "$(tacc.kvget ${GITLAB_STORE})" "refresh_token"
#             fi
#         fi
#     fi
# fi

#if ((! tacclab_refreshed_ok)) || ((force)); then

if ((interactive)); then
  prompt_options
fi

# Delegate logic from the `main` function
authheader=$(get_gitlab_auth_header)
main

# else
#     stderr "Gitlab token was still valid. Re-run with --force to invalidate it."
#     exit 0
# fi

# This has to be run last not to rollback changes we've made.
safe_exit

