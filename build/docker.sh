#!/bin/bash

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

DOCKER_INFO=`docker info > /dev/null`
if [ $? -ne 0 ] ; then die "Docker not found or unreachable. Exiting." ; fi

if [ "$COMMAND" == 'build' ];
then

docker build --rm=true -t ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION} -f ${TENANT_DOCKERFILE} .
if [ $? -ne 0 ] ; then die "Error on build. Exiting." ; fi

IMAGEID=`docker images -q  ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION}`
if [ $? -ne 0 ] ; then die "Can't find image ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION}. Exiting." ; fi

docker tag ${IMAGEID} ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest
if [ $? -ne 0 ] ; then die "Error tagging with 'latest'. Exiting." ; fi

fi


if [ "$COMMAND" == 'release' ];
then

docker push ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION} && docker push ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest

if [ $? -ne 0 ] ; then die "Error pushing to Docker Hub. Exiting." ; fi
fi


if [ "$COMMAND" == 'clean' ];
then

docker rmi -f ${TENANT_DOCKER_ORG}/${IMAGENAME}:${SDKVERSION} && docker rmi -f ${TENANT_DOCKER_ORG}/${IMAGENAME}:latest

if [ $? -ne 0 ] ; then die "Error deleting local images. Exiting." ; fi
fi
