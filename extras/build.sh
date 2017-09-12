#!/usr/bin/env bash

_DEST=$1
if [ -z "$_DEST" ];
    then _DEST="artifacts"
fi

mkdir -p $_DEST
for F in templates templates/systems bin/util examples
do
    mkdir -p "$_DEST/$F"
done

# User storage and excution system templates
cp -fR src/templates/*.jsonx ${_DEST}/templates
cp -fR src/bin ${_DEST}/
