#!/bin/bash

cp VERSION VERSION.bak
echo "develop" > VERSION

_VERSION="$(echo -n $(cat VERSION))"
make distclean

make docker
make docker-release

mv VERSION.bak VERSION
