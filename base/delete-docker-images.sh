#!/usr/bin/env bash
IMAGE_NAME_ARG="$1"
DEFAULT_JAVA_IMAGE_NAME="vaxiom/AXIOJAVA8"
DEFAULT_TOMCAT_IMAGE_NAME="vaxiom/AXIOVM01TOMCAT7"
DEFAULT_BASE_IMAGE_NAME="vaxiom/centos"

USAGE_STR="$(basename $0) <name of the image>"

usage() {
        local RC=0
        
		if [ ! $# -eq 1 ];then
			echo "$USAGE_STR"
			echo "  e.g.,: ./delete-docker-images.sh $DEFAULT_BASE_IMAGE_NAME"
			echo "  e.g.,: ./delete-docker-images.sh $DEFAULT_JAVA_IMAGE_NAME"
			echo "  e.g.,: ./delete-docker-images.sh $DEFAULT_TOMCAT_IMAGE_NAME"
			
			RC=1
		fi
		
		if [ -z "$IMAGE_NAME_ARG" ];then				
			RC=1
			echo "$USAGE_STR"
		fi
		
        return $RC
}


wrapUp() {
        cd $HOME_DIR
}

deleteDockerImage() {
	local RC=0
    local IMAGE_NAME="$1"
    local DOCKER_IMAGES_STR=""
	local DOCKER_CONTAINER_ID=""
    local DOCKER_IMAGE_ID=""
	
	
    if [ -z "$IMAGE_NAME" ];then
        echo "ERROR: missing docker image name..."
        RC=1
    fi
	
	if [ $RC -eq 0 ];then
		echo "INFO: Searching for $IMAGE_NAME image(s)..."
		echo "INFO: DELETING EXISTING DOCKER CONTAINERS FOR $IMAGE_NAME..."
		for container in `docker ps -a | grep $IMAGE_NAME`; do
			DOCKER_IMAGES_STR=$(echo '$container' | sed 's/  */\ /g')
			declare -a DOCKER_IMAGE_ARRAY=($DOCKER_IMAGES_STR)
			DOCKER_CONTAINER_ID${DOCKER_IMAGE_ARRAY[0]}
			echo "INFO: Deleting container: $DOCKER_CONTAINER_ID ..."
			docker rm -f $DOCKER_CONTAINER_ID
			if [ ! $? -eq 0 ];then
				echo "WARNING: Error deleting container $container"
			fi
		done

		echo "INFO: DELETING EXISTING DOCKER IMAGES..."
		for image in `docker images -a | grep $IMAGE_NAME`; do
			local DOCKER_IMAGES_STR=$(echo '$image' | sed 's/  */\ /g')
			declare -a DOCKER_IMAGE_ARRAY=($DOCKER_IMAGES_STR)
			DOCKER_IMAGE_ID=${DOCKER_IMAGE_ARRAY[2]}

			echo "INFO: Deleting container: $image ..."
			docker rmi -f $DOCKER_IMAGE_ID
			if [ $? -eq 0 ];then
				echo "WARNING: Error deleting image $image"
			fi
		done
    fi
        
    return $RC
}

main() {
	local RC=1

	if ( usage ) 
	then
		if ( deleteDockerImage "$IMAGE_NAME_ARG" )
		then
			echo "SUCCESS:  Job completed without errors."
			RC=0		
		fi
	fi
}

main
wrapUp
