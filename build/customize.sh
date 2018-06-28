#!/usr/bin/env bash

# $(OBJ)
TARGET=$1

if [ ! -d "${TARGET}" ]
then
    mkdir -p "${TARGET}" && \
    echo "Created target directory ${TARGET}."
fi

cp -fR tacc-cli-base/* ${TARGET}/
cp -fR abaco-cli/* ${TARGET}/bin
cp VERSION ${TARGET}/SDK-VERSION
