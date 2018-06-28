#!/usr/bin/env bash
#
# submodules.sh
#


function submod() {

    local REPO=$1
    local DEST=$2
    local BRANCH=$3

    if [ -n "$BRANCH" ];
    then
        BRANCH="master"
    fi
    
    {
        git submodule add $REPO $DEST && cd $DEST && git checkout $BRANCH && git pull origin $BRANCH
    } || {
        echo "$REPO not added as a submodule"
    }

}

# CLI_BASE_REPO is an environment variable specified in `configuration.rc` at
# the root of the dev tree (see `config/sample.configuration.rc` for an
# example). This environment variable corresponds to the uri of the Agave cli.
if [ ! -z "$CLI_BASE_REPO" ]
then
    submod $CLI_BASE_REPO $CLI_BASE_DEST $CLI_BASE_BRANCH
fi


# ABACO_CLI_REPO is an environment variable specified in `configuration.rc` at
# the root of the dev tree (see `config/sample.configuration.rc` for an
# example). This varibale corresponds to the uri for the Abaco cli.
if [ ! -z "$ABACO_CLI_REPO" ]
then
    submod $ABACO_CLI_REPO $ABACO_CLI_DEST $ABACO_CLI_BRANCH
fi
