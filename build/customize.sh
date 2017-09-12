#!/usr/bin/env bash

# $(OBJ)
TARGET=$1

if [ ! -d "${TARGET}" ]
then
    mkdir -p "${TARGET}" && \
    echo "Created target directory ${TARGET}."
fi

cp -fR tacc-cli-base/* ${TARGET}/
cp VERSION ${TARGET}/SDK-VERSION

# Extras
if [ -f "extras/Makefile" ];
then
    cd extras && make && make install
else
    rsync --exclude=".*" --exclude=".*/" -azp ./extras/ tacc-cloud-cli
fi
