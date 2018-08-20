#!/bin/bash
#
# taccreg-auth.sh
# Relies on globals
#  - registryuser
#  - registrypass
#  - registryuri
#  - REGISTRY_STORE


function __encregpw() {
    echo -n "$1" | base64
}

function __decregpw() {
    echo -n "$1" | base64 --decode
}

function get_registry_user() {

    regstore=$(kvget $TACCLAB_CACHE_DIR ${REGISTRY_STORE})

    _username=$(echo ${regstore} | jq -r .username)
    if [ ! -z "${_username}" ] && [ "${_username}" != "null" ]; then
        echo ${_username}
    else
        echo ""
    fi
}

function get_registry_org() {

    regstore=$(kvget $TACCLAB_CACHE_DIR ${REGISTRY_STORE})

    _organization=$(echo ${regstore} | jq -r .organization)
    if [ ! -z "${_organization}" ] && [ "${_organization}" != "null" ]; then
        echo ${_organization}
    else
        echo ""
    fi
}

function get_registry_pass() {

    regstore=$(kvget $TACCLAB_CACHE_DIR ${REGISTRY_STORE})
    _pass1=$(echo ${regstore} | jq -r .secure)
    if [ ! -z "${_pass1}" ] && [ "${_pass1}" != "null" ]; then
        _pass=$(__decregpw ${_pass1})
        if [ ! -z "${_pass}" ]; then
            echo ${_pass}
        fi
    else
        echo ""
    fi
}

function get_registry_uri() {

    regstore=$(kvget $TACCLAB_CACHE_DIR ${REGISTRY_STORE})
    _reguri=$(echo ${regstore} | jq -r .baseurl)
    if [ ! -z "${_reguri}" ]; then
        echo ${_reguri}
    else
        echo ""
    fi
}

function registry_login() {

    if ((! REGISTRY_LOGIN_SUCESS)); then
        if [ ! -z "${registryuser}" ] && [ ! -z "${registrypass}" ]; then
            out "Authenticating as ${registryuser}..."
            echo "${registrypass}" | docker login -u ${registryuser} --password-stdin ${registryuri}
            if [ "$?" != 0 ]; then
                err "Authentication failed"
            else
                REGISTRY_LOGIN_SUCESS=1
                TIMESTAMP=$(date +%s)
                kvset $TACCLAB_CACHE_DIR ${REGISTRY_STORE} "{\"username\":\"${registryuser}\",\"secure\":\"$(__encregpw $registrypass)\",\"created_at\":\"${TIMESTAMP}\",\"expires_in\":\"-1\", \"organization\":\"${registryorg}\"}"
            fi
        else
            err "Both --username and --password must be supplied to authenticate to a Docker registry."
        fi
    fi
}

function registry_logout() {

    local _user=$(get_registry_user)
    local _org=$(get_registry_org)

    docker logout ${registryuri} ; \
        kvset $TACCLAB_CACHE_DIR ${REGISTRY_STORE} "{\"organization\":\"${_org}\",\"username\":\"${_user}\",\"secure\":\"\",\"created_at\":\"$TIMESTAMP\",\"expires_in\":\"-1\"}"
    REGISTRY_LOGIN_SUCESS=0

}
