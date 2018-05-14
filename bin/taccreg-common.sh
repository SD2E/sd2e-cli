#!/bin/bash
#
# taccreg-common.sh

if [[ -z "$DIR" ]]; then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# This is set in taccreg-login to allow the command to run
# in embedded mode. It's otherwise not to be used.
REGISTRY_LOGIN_SUCESS=0

source ${DIR}/taccreg-auth.sh

function prompt_options() {

    for val in ${interactive_opts[@]}; do
      if [[ $val == "username" ]]; then
        savedusername=""
        if [ ! -z "$registryuser" ]; then
            savedusername=$registryuser
        else
            savedusername=$(get_registry_user)
            if [ ! -z "$savedusername" ]; then
                registryuser=$savedusername
            fi
        fi
        echo -n "Registry username [$savedusername]: "; read savedusername
        if [ ! -z "$savedusername" ]; then
            registryuser=$savedusername
        fi
    elif [[ $val == "organization" ]]; then
        savedorg=""
        if [ ! -z "$registryorg" ]; then
            savedorg=$registryorg
        else
            savedorg=$(get_registry_org)
            if [ ! -z "$savedorg" ]; then
                registryorg=$savedorg
            fi
        fi
        echo -n "Registry organization (optional) [$savedorg]: "; read savedorg
        # Allow it to be empty
        registryorg=$savedorg
    elif [[ $val == "password" ]]; then
       savedpass=""
        if [ ! -z "$registrypass" ]; then
            savedpass=$registrypass
        else
            savedpass=$(get_registry_pass)
            if [ ! -z "$savedpass" ]; then
                registrypass=$savedpass
            fi
        fi
        _maskedpass=$(maskpass "${savedpass}")
        echo -n "Registry password [${_maskedpass}]: "; stty -echo; read savedpass; stty echo; echo
        if [ ! -z "$savedpass" ]; then
            registrypass=$savedpass
        fi
      fi
    done

}

# Helpers
# override version from cli-commion.sh
function version() {
    out "\nTACC Registry CLI v0.1"
}

