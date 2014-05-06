#!/usr/bin/env bash
#./build-docker-image.sh centos latest id_rsa BASE
set -e
HOME_DIR=`pwd`
BASE_DIR="/opt/vaxiom-docker/base/"
CENTOS_SRC_DIR="centos/"
DOCK_USER="vaxiom"
DEFAULT_CONTAINER="centos"
DEFAULT_TAG="latest"
DEFAULT_SSH_KEY="id_rsa"
DEFAULT_ACTION="ALL"

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

container=$1
tag=$2
ssh_key=$3
action=$4

if [ -z "$container" ];then
	container="$DEFAULT_CONTAINER"
fi

if [ -z "$tag" ];then
	tag="$DEFAULT_TAG"
fi

if [ -z "$ssh_key" ];then
	ssh_key="$DEFAULT_SSH_KEY"
fi

if [ -z "$action" ];then
	action="$DEFAULT_ACTION"
fi

DOCKER_BASE_IMAGE_NAME="$DOCK_USER/$container"
DOCKER_BASE_IMAGE="/opt/vaxiom-docker/base/centos/"
DOCKER_BASE_IMAGE_SRC="/opt/vaxiom-docker/base/centos/src/"

DOCKER_JAVA_IMAGE_NAME="vaxiom/AXIOJAVA8"
DOCKER_JAVA_IMAGE="/opt/vaxiom-docker/java8/centos/"
DOCKER_JAVA_IMAGE_SRC="/opt/vaxiom-docker/java8/centos/src/"

DOCKER_TOMCAT_IMAGE_NAME="vaxiom/AXIOVM01TOMCAT7"
DOCKER_TOMCAT_IMAGE="/opt/vaxiom-docker/tomcat7/centos/"
DOCKER_TOMCAT_IMAGE_SRC="/opt/vaxiom-docker/tomcat7/centos/src/"

usage() {
# ./build-docker-image.sh centos latest id_rsa BASE
	local RC=0

	if [ -z $container ];then
		RC=1
	fi

	if [ -z $tag ];then
		RC=1
	fi

	if [ ! $RC -eq 0 ];then
		echo "INFO:  Usage:  $(basename $0) <container name> <tag> [ssh pub key] <optional image action>"
		echo "INFO:  Usage example 1:  $(basename $0) centos latest $HOME/$USER/.ssh/id_rsa.pub"
		echo "INFO:  Usage example 2:  $(basename $0) centos latest $HOME/$USER/.ssh/id_rsa.pub BASE"
		echo "INFO:  Usage example 3:  $(basename $0) centos latest $HOME/$USER/.ssh/id_rsa.pub JAVA"
		echo "INFO:  Usage example 4:  $(basename $0) centos latest $HOME/$USER/.ssh/id_rsa.pub TOMCAT"
	fi

	return $RC
}

does_file_exists(){
	local f="$1"
	[[ -f "$f" ]] && return 0 || return 1
}

wrapUp() {
    cd $HOME_DIR
}

genSSHKeys() {
	local RC=0
	local key="$1"
	local pubExt="pub"
	local USER_SSH_HOME="$HOME/.ssh"
	local key="$USER_SSH_HOME/$key"
	local pub="${key}.${pubExt}"
		
	#local key="id_rsa"
	#local pubExt="id_rsa_pub.pub"
	
	echo "INFO: Generating ssh keys for: $key and $pub ..."
	if [ -f "$SSH_CONFIG_FILE" ];then
		echo "INFO: Executing cmd: sudo cp -f $SSH_CONFIG_FILE $DOCKER_BASE_IMAGE_SRC"
		sudo cp -f "$SSH_CONFIG_FILE" "$DOCKER_BASE_IMAGE_SRC"
		if [ ! $? -eq 0 ];then
			RC=1
			echo "ERROR: Unable to run cmd: sudo cp -f $SSH_CONFIG_FILE $DOCKER_BASE_IMAGE_SRC"
		fi
	else
		RC=1
		echo "ERROR: Unable to locate the sshd_config file:  $SSH_CONFIG_FILE"
	fi

	if [[ $RC -eq 0 && ! -d "$USER_SSH_HOME" ]];then
		mkdir -p "$USER_SSH_HOME"
		if [ ! $? -eq 0 ];then
			RC=1
			echo "ERROR: Unable to create directory: $USER_SSH_HOME"
		fi
	fi
	
	if [[ $RC -eq 0 && ! -f "$key" ]]; then
		echo "INFO:  No public ssh key found. Generating a new ssh key"
		echo "INFO:  Running cmd:  ssh-keygen -q -t rsa -N '' -f $key"
		ssh-keygen -q -t rsa -N "" -f "$key"
		if [ ! $? -eq 0 ];then
			RC=1
		fi
	fi
	
	if [[ $RC -eq 0 && -f "$key" ]];then
		RC=1
		cp -f "$key" "$DOCKER_BASE_IMAGE_SRC"
		if [[ $? -eq 0 && -f "$pub" ]];then
			cat "$pub" >> "$USER_SSH_HOME/authorized_keys"
			cp -f "$pub" "$DOCKER_BASE_IMAGE_SRC"
			if [ $? -eq 0 ];then
				RC=0
				chmod 700 "$USER_SSH_HOME"
				chmod 600 "$key"
			fi			
		fi
		
		if [ ! $RC -eq 0 ];then
			RC=1
			echo "ERROR:  Unable to run cmd: mv -f $pub $DOCKER_BASE_IMAGE_SRC"			
		fi
	else
		RC=1
		echo "ERROR:  Unable to generate or locate rsa keys:  ssh-keygen -q -t rsa -N '' -f $key"
	fi
	

	return $RC
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
		for container in `docker ps | grep $IMAGE_NAME`; do
			DOCKER_IMAGES_STR=$(echo '$container' | sed 's/  */\ /g')
			declare -a DOCKER_IMAGE_ARRAY=($DOCKER_IMAGES_STR)
			DOCKER_CONTAINER_ID${DOCKER_IMAGE_ARRAY[0]}
			echo "INFO: Deleting container: $DOCKER_CONTAINER_ID ..."
			docker stop $DOCKER_CONTAINER_ID
			if [ ! $? -eq 0 ];then
				echo "WARNING: Error deleting container $container"
			fi
		done
		
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

			echo "INFO: Deleting image: $image ..."
			docker rmi -f $DOCKER_IMAGE_ID
			if [ $? -eq 0 ];then
				echo "WARNING: Error deleting image $image"
			fi
		done
    fi
        
    return $RC
}

dockerBuildImage() {
	local RC=0
	local TMP_HOME=`pwd`
	
	local IMAGE_NAME="$1"
	local IMAGE_DIR_BASE="$2"
	local IMAGE_TAG_NAME="$3"
	
	if [ -z "$IMAGE_NAME" ];then
		echo "ERROR:  Invalid image name!"
		RC=1
	fi
	
	if [ -z "$IMAGE_TAG_NAME" ];then
		IMAGE_TAG_NAME="latest"
	fi
	
	echo "INFO: Building docker image $IMAGE_NAME ..."		
	if [ -d "$IMAGE_DIR_BASE" ];then
		cd "$IMAGE_DIR_BASE"
		if [ $? -eq 0 ];then
			if [ $RC -eq 0 ];then	
				deleteDockerImage "$IMAGE_NAME"
				docker build -t $IMAGE_NAME:$IMAGE_TAG_NAME .
				if [ $? -eq 0 ];then
					echo "INFO:  Docker image built using: docker build -t $IMAGE_NAME:$IMAGE_TAG_NAME ."
					RC=0
				else
					RC=1
					echo "ERROR:  building docker image: docker build -t $IMAGE_NAME:$IMAGE_TAG_NAME ."
				fi
			fi
		fi
	else
		echo "ERROR:  Unable to locate directory:  $IMAGE_DIR_BASE"
		RC=1
	fi

	cd $TMP_HOME
	return $RC
}

buildAllImages() {
	if ( ! dockerBuildImage "$DOCKER_BASE_IMAGE_NAME" "$DOCKER_BASE_IMAGE" "$tag" )
	then
		return 1
	fi

	if ( ! dockerBuildImage "$DOCKER_JAVA_IMAGE_NAME" "$DOCKER_JAVA_IMAGE" "$tag" )
	then
		return 1
	fi

	if ( ! dockerBuildImage "$DOCKER_TOMCAT_IMAGE_NAME" "$DOCKER_TOMCAT_IMAGE" "$tag" )
	then
		return 1
	fi

	return 0
}

checkAction() {
	local f="$1"
	local caSSHKey="$2"
	local RC=0
	
	if [[ ! -z "$f" && ! -z "$caSSHKey" ]];then
		if [[ "$f" == "BASE" && $RC -eq 0 ]];then
			if ( genSSHKeys "$caSSHKey" )
			then
				dockerBuildImage "$DOCKER_BASE_IMAGE_NAME" "$DOCKER_BASE_IMAGE" "$tag"
				RC=$?
			else
				RC=1
			fi
		fi
		
		if [[ "$f" == "JAVA" && $RC -eq 0 ]];then
			dockerBuildImage "$DOCKER_JAVA_IMAGE_NAME" "$DOCKER_JAVA_IMAGE" "$tag"
			RC=$?
		fi

		if [[ "$f" == "TOMCAT" && $RC -eq 0 ]];then
			dockerBuildImage "$DOCKER_TOMCAT_IMAGE_NAME" "$DOCKER_TOMCAT_IMAGE" "$tag"
			RC=$?
		fi

		if [[ "$f" == "ALL" && $RC -eq 0 ]];then
			if ( genSSHKeys "$caSSHKey" )
			then
				buildAllImages
				RC=$?
			else
				RC=1
			fi
		fi
	else
		RC=1
		echo "ERROR:  No action selected or an SSH Key file was not provided.  i.e. JAVA, TOMCAT, BASE, ALL"
	fi

	return $RC
}

main() {
	local RC=1
	
	if ( usage ) 
	then
		if [ -d "$BASE_DIR" ];then
			cd $BASE_DIR
				if [ -d "$CENTOS_SRC_DIR" ];then
						cd $CENTOS_SRC_DIR						
						if ( checkAction "$action" "$ssh_key" )
						then
								echo "SUCCESS:  Job completed without errors."
								RC=0
						else
								echo "ERROR: An error occurred... oops"
						fi
				else
						echo "ERROR: Unable to locate directory: $CENTOS_SRC_DIR"
				fi
		else
				echo "ERROR: Unable to locate directory: $BASE_DIR"
		fi
	fi
	
	return $RC
}

main
wrapUp
