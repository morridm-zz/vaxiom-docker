#!/usr/bin/env bash
HOME_DIR=`pwd`
BASE_DIR="/opt/vaxiom-docker/base/"
CENTOS_SRC_DIR="centos/"
DOCKER_BASE_IMAGE="/opt/vaxiom-docker/base/centos/"
DOCKER_JAVA_IMAGE="/opt/vaxiom-docker/java8/centos/"
DOCKER_TOMCAT_IMAGE="/opt/vaxiom-docker/tomcat7/centos/"

ssh_key="id_rsa_pub"
DOCK_USER="vaxiom"
container=$1
tag=$2
action=$4

usage() {
        local RC=0
		[[ $# -eq 3 ]] && ssh_key=$3
		
		if [[ $# -lt 2 ]];then			
			RC=1
		fi
		
		if [[ ! $RC -eq 0 ]];then
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
        local RC=1
        
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
	local CURR_DIR=`pwd`
    
	cd $BASE_DIR
	
	echo "Executing './delete-docker-images.sh $IMAGE_NAME' as root"
	sudo su root -c ./delete-docker-images.sh $IMAGE_NAME
	echo "Finished executing delete-docker-images.sh and switched back to user $(whoami)"
	
	cd $CURR_DIR
        
    return $RC
}

dockerBuildBaseImage() {
        local RC=1
        local TMP_HOME=`pwd`
        local IMAGE_NAME="$DOCK_USER/$container"
        deleteDockerImage "$IMAGE_NAME"

        echo "INFO: Building docker image $IMAGE_NAME ..."
        if [ -d "$DOCKER_BASE_IMAGE" ];then
                docker build -t $IMAGE_NAME:$tag .
                if [ $? -eq 0 ];then
                        echo "INFO:  Docker image built using: docker build -t $IMAGE_NAME:$tag ."
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
                docker build -t $IMAGE_NAME:latest .
                if [ $? -eq 0 ];then
                        echo "INFO:  Docker image built using: docker build -t $IMAGE_NAME:latest ."
                        RC=0
                else
                        echo "ERROR:  building docker image: docker build -t $IMAGE_NAME:latest ."
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
                docker build -t $IMAGE_NAME:latest .
                if [ $? -eq 0 ];then
                        echo "INFO:  Docker image built using: docker build -t $IMAGE_NAME:latest ."
                        echo "INFO: Run cmd=> docker run -d -p 0.0.0.0:49153:22 -p 0.0.0.0:49154:27018 -p 0.0.0.0:49155:28017 -p 0.0.0.0:49156:3306 -p 0.0.0.0:49157:4444 -p 0.0.0.0:49158:4567 -p 0.0.0.0:49159:80 -p 0.0.0.0:49160:27017 -p 0.0.0.0:49161:27019 -p 0.0.0.0:49162:443 -p 0.0.0.0:49163:4568 vaxiom/AXIOVM01TOMCAT7:latest"
                        RC=0
                else
                        echo "ERROR:  building docker image: docker build -t $IMAGE_NAME:latest ."
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
