#!/usr/bin/env bash

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

if [ ! -z "CLI_BASE_REPO" ]
then
    submod $CLI_BASE_REPO $CLI_BASE_DEST $CLI_BASE_BRANCH
fi
