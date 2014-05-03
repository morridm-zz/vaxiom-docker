#!/usr/bin/env bash

#Setup env variables
HOME_DIR=`pwd`
BASE_DIR="/opt/vaxiom-docker/base/"
CENTOS_SRC_DIR="centos/"

DOCKER_BASE_IMAGE="/opt/vaxiom-docker/base/centos/"
DOCKER_JAVA_IMAGE="/opt/vaxiom-docker/java8/centos/"
DOCKER_TOMCAT_IMAGE="/opt/vaxiom-docker/tomcat7/centos/"

ssh_key=id_rsa_pub
DOCK_USER="vaxiom"
container=$1
tag=$2
action=$4

###Usage: ./build-docker-image centos latest $HOME/$USER/.ssh/id_rsa.pub
usage() {
        local RC=0
        [[ $# -lt 2 ]] && echo "$(basename $0) <container name> <tag> [ssh pub key]" && RC=1
        return $RC
}

# Common function to see if a file exists
does_file_exists(){
        local f="$1"
        [[ -f "$f" ]] && return 0 || return 1
}

wrapUp() {
        cd $HOME_DIR
}

genSSHKeys() {
        local RC=1
        [[ $# -eq 3 ]] && ssh_key=$3

        if [[ ! -f $ssh_key ]]; then
            echo "No public ssh key found. Generating a new ssh key"
            echo ""

            ssh-keygen -q -t rsa -N "" -f id_rsa
            if [ $? -eq 0 ];then
                if [ -f "id_rsa" ];then
                        if [ -f "id_rsa.pub" ];then
                            RC=0
                        fi
                fi
            else
                echo "ERROR:  Unable to generate rsa keys:  ssh-keygen -q -t rsa -N "" -f id_rsa"
            fi
        else
                RC=0
        fi

        return $RC
}

deleteDockerImage() {
        local RC=0
        local IMAGE_NAME="$1"
        local DOCKER_DATE=$(date +%d%m%Y%I%M%S)
        local DOCKER_IMAGES_STR=""
        local DOCKER_CONTAINER_ID=""
        local DOCKER_IMAGE_ID=""

        if [ -z "$IMAGE_NAME" ];then
                echo "ERROR: missing docker image name..."
                return 1
        fi

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

        return $RC
}

dockerBuildBaseImage() {
        local RC=1
        local TMP_HOME=`pwd`
        local IMAGE_NAME="$DOCK_USER/$container"
        deleteDockerImage "$IMAGE_NAME"

        echo "INFO: Building docker image $IMAGE_NAME ..."
        if [ -d "$DOCKER_BASE_IMAGE" ];then
                sudo docker build -t $IMAGE_NAME:$tag .
                if [ $? -eq 0 ];then
                        echo "INFO:  Docker image built using: sudo docker build -t $IMAGE_NAME:$tag ."
                        RC=0
                else
                        echo "ERROR:  building docker image: docker build -t $IMAGE_NAME:$tag ."
                fi
        else
                echo "ERROR: Unable to locate directory: $DOCKER_BASE_IMAGE"
        fi

        cd $TMP_HOME
        return $RC
}

dockerBuildJavaImage() {
        local RC=1

        local TMP_HOME=`pwd`
        local IMAGE_NAME="vaxiom/AXIOJAVA8"
        deleteDockerImage "$IMAGE_NAME"

        echo "INFO: Building docker image $IMAGE_NAME ..."
        if [ -d "$DOCKER_JAVA_IMAGE" ];then
                cd $DOCKER_JAVA_IMAGE
                sudo docker build -t $IMAGE_NAME:latest .
                if [ $? -eq 0 ];then
                        echo "INFO:  Docker image built using: sudo docker build -t $IMAGE_NAME:latest ."
                        RC=0
                else
                        echo "ERROR:  building docker image: sudo docker build -t $IMAGE_NAME:latest ."
                fi
        else
                echo "ERROR: Unable to locate directory: $DOCKER_JAVA_IMAGE"
        fi

        cd $TMP_HOME
        return $RC
}

dockerBuildTomcatImage() {
        local RC=1
        local TMP_HOME=`pwd`
        local IMAGE_NAME="vaxiom/AXIOVM01TOMCAT7"

        echo "INFO: Building docker image $IMAGE_NAME ..."
        deleteDockerImage "$IMAGE_NAME"

        if [ -d "$DOCKER_TOMCAT_IMAGE" ];then
                cd $DOCKER_TOMCAT_IMAGE
                sudo docker build -t $IMAGE_NAME:latest .
                if [ $? -eq 0 ];then
                        echo "INFO:  Docker image built using: sudo docker build -t $IMAGE_NAME:latest ."
                        echo "INFO: Run cmd=> docker run -d -p 0.0.0.0:49153:22 -p 0.0.0.0:49154:27018 -p 0.0.0.0:49155:28017 -p 0.0.0.0:49156:3306 -p 0.0.0.0:49157:4444 -p 0.0.0.0:49158:4567 -p 0.0.0.0:49159:80 -p 0.0.0.0:49160:27017 -p 0.0.0.0:49161:27019 -p 0.0.0.0:49162:443 -p 0.0.0.0:49163:4568 vaxiom/AXIOVM01TOMCAT7:latest"
                        RC=0
                else
                        echo "ERROR:  building docker image: sudo docker build -t $IMAGE_NAME:latest ."
                fi
        else
                echo "ERROR: Unable to locate directory: $DOCKER_TOMCAT_IMAGE"
        fi

        cd $TMP_HOME
        return $RC
}

buildDockerImages() {
        if ( ! dockerBuildBaseImage )
        then
                return 1
        fi

        if ( ! dockerBuildJavaImage )
        then
                return 1
        fi

        if ( ! dockerBuildTomcatImage )
        then
                return 1

        fi

        return 0
}

checkAction() {
        local f="$1"
        local RC=1

        if [ "$f" == "JAVA" ];then
                dockerBuildJavaImage
                RC=0
        fi

        if [ "$f" == "TOMCAT" ];then
                dockerBuildTomcatImage
                RC=0
        fi

        if [ "$f" == "BASE" ];then
                dockerBuildBaseImage
                RC=0
        fi

        if [ -z "$f" ];then
                buildDockerImages
                RC=0
        fi

        return $RC
}

main() {
        local RC=1

        if [ -d "$BASE_DIR" ];then
        	cd $BASE_DIR
                if [ -d "$CENTOS_SRC_DIR" ];then
                        cd $CENTOS_SRC_DIR
                        genSSHKeys
                        if ( checkAction "$action" )
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
}

main
wrapUp
