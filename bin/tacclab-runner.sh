#!/bin/bash
#
# tacclab-runner.sh

# Main processing logic for the scripts
# use the cached credentials if available

function get_gitlab_token_remaining_time() {

  local TOKENSTORE="${1}"
  if [ -z "${TOKENSTORE}" ]; then
    # Default to Agave store for now
    TOKENSTORE="gitlab"
  fi

  auth_cache=$(kvget $TACCLAB_CACHE_DIR ${TOKENSTORE})

  jsonval expires_in "$auth_cache" "expires_in"
  jsonval created_at "$auth_cache" "created_at"

  if [ "${expires_in}" == "null" ] || [[ -z "$expires_in" ]] || [[ -z "$created_at" ]] || [[ "$created_at" == "null" ]]; then
    echo "0"
  else
    created_at=${created_at%.*}
    expires_in=${expires_in%.*}
    expiration_time=$(( $created_at + $expires_in ))
    current_time=$(date +%s)
    time_left=$(( $expiration_time - $current_time ))
    echo "${time_left}"
  fi
}

if [ "$gitlab_disable_cache" -ne 1 ] && [ -z "$gitlab_access_token" ]; then # user did not specify an gitlab_access_token as an argument
    tokenstore=$(kvget $TACCLAB_CACHE_DIR ${GITLAB_STORE})
#    stderr $tokenstore
    if [ -n "$tokenstore" ]; then
        jsonval gitlabusername "${tokenstore}" "username"
        jsonval gitlab_access_token "${tokenstore}" "access_token"
        jsonval gitlab_refresh_token "${tokenstore}" "refresh_token"

        # stderr "username: $gitlabusername"
        # stderr "access_token: $gitlab_access_token"
        # stderr "refresh_token: $gitlab_refresh_token"
        # jsonval baseurl "${tokenstore}" "baseurl"
        # stderr "${baseurl}"

        # Mechanism to auto-refresh expired bearer tokens
        if [ -n "$gitlab_refresh_token" ]; then
            token_life_remaining=$(get_gitlab_token_remaining_time ${GITLAB_STORE})
            # stderr "remain: $token_life_remaining"
            # exit 0
            tacclab_refreshed_ok=1 # assume refresh is OK - this is set to zero in auto_auth_refresh
            if [ ${token_life_remaining}  -lt  60 ]; then
                stderr "Gitlab token has expired. Refreshing..."
                gitlab_auto_auth_refresh
                tokenstore=$(kvget $TACCLAB_CACHE_DIR ${GITLAB_STORE})
                jsonval gitlab_access_token "${tokenstore}" "access_token"
                jsonval gitlab_refresh_token "${tokenstore}" "refresh_token"
                # stderr "access_token: $gitlab_access_token | refresh_token: ${gitlab_refresh_token}"
            fi
        fi
    fi
fi

if ((interactive)); then
  prompt_options
fi

# Delegate logic from the `main` function
authheader=$(get_gitlab_auth_header)
main

# This has to be run last not to rollback changes we've made.
safe_exit
