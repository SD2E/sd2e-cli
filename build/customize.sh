#!/usr/bin/env bash
#
# customize.sh
#
# Package executables and scripts from submodules and this repo into a $TARGET
# directory for it to be tar'd and packaged as a new release.

# $TARGET corresponds to the final location of the executables and scripts to
# be packaged as a release ($OBJ in the main Makefile).
TARGET=$1

if [ ! -d "${TARGET}" ]
then
    mkdir -p "${TARGET}" && \
    echo "Created target directory ${TARGET}."
fi

cp -fR tacc-cli-base/* ${TARGET}/
cp -fR abaco-cli/* ${TARGET}/bin
cp VERSION ${TARGET}/SDK-VERSION
