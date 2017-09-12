#!/usr/bin/env bash

_TAG=$1

echo "Clearing remote/local tags..."

if [ -z "${_TAG}" ]
then
    _TAG=$(git tag)
    echo "Found: $_TAG"
fi

if [ -z "${_TAG}" ];
then
    echo "No tags to remove. Quitting."
    exit 1
fi

for T in "${_TAG}"
do
    echo "Deleting origin:$T"
    git push --delete origin $T
    echo "Deleting local $T"
    git tag --delete $T
done
