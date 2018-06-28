#!/usr/bin/env bash
#
# submodules.sh
#
# Add and update submodules.
#
# CLI_BASE_REPO is an environment variable specified in `configuration.rc` at   
# the root of the dev tree (see `config/sample.configuration.rc` for an         
# example). This environment variable corresponds to the uri of the Agave cli.
#
# ABACO_CLI_REPO is an environment variable specified in `configuration.rc` at
# the root of the dev tree (see `config/sample.configuration.rc` for an
# example). This varibale corresponds to the uri for the Abaco cli.


# submod - adds a submodule to a specified location and pulls the latest
# commits of a specified branch. If submodule already exists then it just
# populates the module.
#
# REPO   - uri of repo to add as submodule.
# DEST   - destination of where to add the module with respect to the root of
# this repo.
# BRANCH - branch to build off of.
function submod() {

    local REPO=$1
    local DEST=$2
    local BRANCH=${3:-master}

    git submodule add $REPO $DEST

    git submodule update --init $DEST 
    
    ( cd $DEST && git checkout $BRANCH )
}

# Agave CLI.
if [ ! -z "$CLI_BASE_REPO" ]
then
    submod $CLI_BASE_REPO $CLI_BASE_DEST $CLI_BASE_BRANCH
fi

# Abaco CLI.
if [ ! -z "$ABACO_CLI_REPO" ]
then
    submod $ABACO_CLI_REPO $ABACO_CLI_DEST $ABACO_CLI_BRANCH
fi
