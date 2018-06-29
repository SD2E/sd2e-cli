#!/bin/bash
#
# docker.sh
#
# By default, this script will build ($COMMAND "build") a docker container 
# image with sd2e-cli executables. Other options are "release", and "clean".
#
# Environment variables specified in configuration.rc (root of dev tree and
# sourced by Makefile): $TENANT_DOCKER_ORG, $TENANT_DOCKERFILE.
#
# Usage:
#   docker.sh sd2e-cloud-cli v1.0.0 build
#

IMAGENAME=$1
SDKVERSION=$2
COMMAND=$3

# Build container image by default.
if [ -z "$COMMAND" ]; then COMMAND="build"; fi


# die - print error message and early terminate with error status.
function die {
	echo "$1"
	exit 1

}


# Build conatiner image with sd2e-cli.
if [ "$COMMAND" == 'build' ];
then
    # Tag image with $SDKVERSION.
    docker build --no-cache --force-rm \
        -f ${TENANT_DOCKERFILE} \
        -t ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION} . || \
        die "Error on build. Exiting."

    # Tag image with "latest".
    IMAGEID=`docker images -q  ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION}` 
    test -z $IMAGEID && die "Can't find image ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION}."
        
    docker tag ${IMAGEID} ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest
fi



# Push conatiner image with sd2e-cli.
if [ "$COMMAND" == 'release' ];
then
    docker push ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION} || \
        die "Error pushing ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION} to Docker Hub."
        
    docker push ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest || \
        die "Error pushing ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest to Docker Hub."
fi



# Remove conatiner image.
if [ "$COMMAND" == 'clean' ];
then
    docker rmi -f ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION}
    docker rmi -f ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest
fi
