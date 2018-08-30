#!/bin/bash
#
# build.sh
#
# Run this script from the root of this repo.
#

# Clean and build release.
make distclean
make release 
git push origin master

# Create container image of release.
make docker-release && make clean
