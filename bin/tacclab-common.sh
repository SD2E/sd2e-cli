#!/bin/bash
#
# tacclab-common.sh
#
# Common helper functions and global variables for TACC Gitlab cli scripts.

# TACC Gitlab versioning info
GITLAB_CLI_VERSION="1.0.0"
GITLAB_VERSION="10.3.3"
GITLAB_API="v4"
GITLAB_TOKEN_TTL=3600

if [[ -z "$DIR" ]]; then
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# Defaults
force=0
quiet=0
verbose=0
veryverbose=0
interactive=1
rich=0
development=$( (("$GITLAB_DEVEL_MODE")) && echo "1" || echo "0" )
gitlab_disable_cache=0 # set to 1 to prevent using auth cache.
# Specific dependency check
# ssh-keygen is needed to fingerprint keys - we just don't
#            do this if ssh-keygen isn't available.
command -v ssh-keygen >/dev/null 2>&1 ; haskeygen=1 || true
args=()

# Read config
_CONFIG=$(get_tenant_config)
if [ -f "${_CONFIG}" ]; then
    source ${_CONFIG}
fi

function version() {
	out "\nTACC Gitlab CLI
  CLI: ${GITLAB_CLI_VERSION}
  API: ${GITLAB_API}
  GitLab: ${GITLAB_VERSION}
"
}

# Keystores
# keystore filenames
AGAVE_STORE="current"
if [ -z "${GITLAB_STORE}" ]; then
    GITLAB_STORE="gitlab"
fi
if [ -z "${REGISTRY_STORE}" ]; then
    REGISTRY_STORE="registry"
fi

# Set Agave and TACC cloud directory
if [ -z "$AGAVE_CACHE_DIR" ]; then
    AGAVE_CACHE_DIR="$HOME/.agave"
fi

if [ -z "$TACCLAB_CACHE_DIR" ]; then
    if [ -z "$AGAVE_CACHE_DIR" ]; then
        TACCLAB_CACHE_DIR="${HOME}/.agave"
    else
        TACCLAB_CACHE_DIR="$AGAVE_CACHE_DIR"
    fi
fi

# Check existence of keystores
# NOTE: Does not validate them!!!
if [ -f "${AGAVE_CACHE_DIR}/${AGAVE_STORE}" ]; then
    export has_agave_store=1
fi
if [ -f "${TACCLAB_CACHE_DIR}/${REGISTRY_STORE}" ]; then
    export has_tacc_registry_store=1
fi
if [ -f "${TACCLAB_CACHE_DIR}/${GITLAB_STORE}" ]; then
    export has_tacc_gitlab_store=1
fi

function open_url() {
    # Launches a browser window if possible
    # https://stackoverflow.com/a/38147878
    URL="${1}"

    if [ ! -z "${URL}" ]; then

        command -v xdg-open >/dev/null 2>&1 && hasxdg=1 || hasxdg=0
        command -v open >/dev/null 2>&1 && hasopen=1 || hasopen=0

        if ((hasxdg)); then
            xdg-open "${URL}"
        elif ((hasopen)); then
            open "${URL}"
        else
            python -mwebbrowser "${URL}"
        fi
    fi
}

# Gitlab specifics

function bootstrap() {

    calling_cli_command=`caller |  awk '{print $2}' | xargs -n 1 sh -c 'basename $0'`
    local currentconfig=$(tacc.kvget ${1})

    if [[ ! -z "${currentconfig}" ]]; then
        gitlab_baseurl=$(jsonquery "$currentconfig" "baseurl")
        gitlab_baseurl="${gitlab_baseurl%/}"
        tenantid=$(jsonquery "$currentconfig" "tenantid")
    fi

}

bootstrap "${GITLAB_STORE}"

# Gitlab-specific pagination
# Note: This is just a clone of the Agave code and doesn't work
#       yet for Gitlab API
function pagination {

	pagination=''
	re='^[0-9]+$'
	if [[ "$limit" =~ $re ]] ; then
		pagination="&limit=$limit"
	fi

	if [[ "$offset" =~ $re ]] ; then
		pagination="${pagination}&offset=$offset"
	fi

	if [[ -n "$responsefilter" ]]; then
		pagination="${pagination}&filter=$responsefilter"
	fi

	if [[ -n "$sortOrder" ]]; then
		pagination="${pagination}&order=$sortOrder"
	fi

	if [[ -n "$sortBy" ]]; then
		pagination="${pagination}&orderBy=$sortBy"
	fi

	echo $pagination
}

function prompt_options() {
    # Can be overridden in tacclab-<function>.sh
    local currentconfig=$(tacc.kvget ${GITLAB_STORE})

    for val in ${interactive_opts[@]}; do
      if [[ $val == "username" ]]; then
        savedusername="none"
        if [ ! -z "$gitlabusername" ]; then
            savedusername=$gitlabusername
        else
            jsonval savedusername "${currentconfig}" "username"
            if [ ! -z "$savedusername" ]; then
                gitlabusername=$savedusername
            fi
        fi
        echo -n "Gitlab username [$savedusername]: "; read savedusername
        if [ ! -z "$savedusername" ]; then
            gitlabusername=$savedusername
        fi
      elif [[ $val == "password" ]]; then
        echo -n "Gitlab password: "; stty -echo; read gitlabpassword; stty echo; echo
      fi
    done

}

function get_gitlab_auth_header() {
	if [[ "$development" -ne 1 ]]; then
		echo "Authorization: Bearer $gitlab_access_token"
	else
		if [[ -f "$DIR/auth-filter.sh" ]]; then
		  echo $(source $DIR/auth-filter.sh);
		else
		  echo " -u \"${gitlabusername}:${gitlabpassword}\" "
		fi
	fi
}

# Refresh the current user token cached in $TACC_CACHE_DIR/GITLAB_STORE. This function can be
# disabled at any time by setting the $GITLAB_DISABLE_AUTO_REFRESH environment variable.
# Refresh will be skipped silently if the refresh token is missing.

function gitlab_auto_auth_refresh()
{
	# AGAVE_DISABLE_AUTO_REFRESH=1
    tacclab_refreshed_ok=0
	if [[ -z "$GITLAB_DISABLE_AUTO_REFRESH" ]];
	then
		# ignore the refresh if the api keys or refresh token are not present in the cache.
		if [[ -n "$gitlab_baseurl" ]] && [[ -n "$gitlab_refresh_token" ]] && [[ -n "$gitlab_access_token" ]];
		then
			# build the refresh command url and form
			__hosturl="$gitlab_baseurl"
			__hosturl=${__hosturl}/oauth/token
			__post_options="grant_type=refresh_token&access_token=${gitlab_access_token}&refresh_token=${gitlab_refresh_token}"

            # stderr "curl -sk -XPOST -d \"${__post_options}\" \"$__hosturl\""
			response=`curl -sk -XPOST -d "${__post_options}" "$__hosturl"`

            gitlaberr=
            jsonval gitlaberr "${response}" "error"
            # stderr "gitlaberr: $gitlaberr"
            # stderr "$response"
			# check response code. if curl exited with a non 200 code, the operation failed
			if [[ ! -z "${gitlaberr}" ]]; then
                if ((! verbose )); then
                    die "${response}"
                else
    				err "Unable to refresh Gitlab token: ${gitlaberr}"
                fi
			# otherwise, update the local cache with the new token and expiration time
			else
#                stderr "Storing tokens.."
				jsonval gitlab_access_token "$response" "access_token"
				jsonval gitlab_refresh_token "$response" "refresh_token"
				expires_in=${GITLAB_TOKEN_TTL}
				created_at=$(date +%s)
				if ((is_gnu)) ; then
					expires_at=`date -d @$(expr $created_at + $expires_in)`
				else
					expires_at=`date -r $(expr $created_at + $expires_in)`
				fi

				tacc.kvset ${GITLAB_STORE} "{\"tenantid\":\"$tenantid\",\"baseurl\":\"$gitlab_baseurl\",\"devurl\":\"$devurl\",\"apisecret\":\"$apisecret\",\"apikey\":\"$apikey\",\"username\":\"$gitlabusername\",\"access_token\":\"$gitlab_access_token\",\"refresh_token\":\"$gitlab_refresh_token\",\"created_at\":\"$created_at\",\"expires_in\":\"$expires_in\",\"expires_at\":\"$expires_at\"}"
                tacclab_refreshed_ok=1
				if  ((verbose)); then
					stderr "Token for ${tenantid}:${gitlabusername} successfully refreshed and cached for ${expires_in} seconds"
				fi


			fi
		fi
	fi
}

function get_gitlab_username(){

    local currentconfig=$(tacc.kvget ${GITLAB_STORE})
    jsonval _username "${currentconfig}" "username"
    if [ ! -z "${_username}" ]; then
        echo "${_username}"
    else
        echo ""
    fi
}

# Tenant-specific gitlab config
function get_gitlab_uri() {

    if [ ! -z "${TACC_GITLAB_URI}" ]; then
        gitlab_gitlab_baseurl=${TACC_GITLAB_URI}
    else
        err "Couldn't get TACC_GITLAB_URI"
    fi

    echo "${gitlab_gitlab_baseurl}"
}

# Tenant-specific gitlab config
function get_gitlab_api() {

    if [ ! -z "${TACC_GITLAB_API}" ]; then
        gitlab_api=${TACC_GITLAB_API}
    else
        gitlab_api="v4"
    fi

    echo "${gitlab_api}"
}

function filter_service_url() {

    tacclab_hosturl="${hosturl%/}"
}
