#!/bin/bash

_VERSION=$(echo -n $(cat VERSION))
source configuration.rc

make clean
make dist

git commit -a -m "Releasing ${_VERSION}"
git tag -a "v${_VERSION}" -m "version ${_VERSION}"
git push origin "v${_VERSION}"
git push origin master

make docker
make docker-release
make clean
