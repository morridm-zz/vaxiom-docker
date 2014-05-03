#!/usr/bin/env bash
set -e

#Variables
HOME_DIR=`pwd`
DOCKER_SRC_HOME="/home/vagrant/docker/"
DOCKERFILE_SSH="Dockfile_4_InstallSSH.txt"
DOCKERFILE_JAVA="Dockfile_5_BuildJava8.txt"
DOCKERFILE_TOMCAT="Dockfile_6_BuildTomcat7.txt"

usage() {
		return 0
}

# Common function to see if a file exists
does_file_exists(){
	local f="$1"
	[[ -f "$f" ]] && return 0 || return 1
}

# Checks to see if the http://Docker.io packages is already installed
dockerExists() {
	echo "INFO: Checking for docker application..."
	if ! builtin type -p docker &>/dev/null; then
		echo "ERROR:  Unable to find docker.io.  Please install docker.io first."
		return 1
	else
		if [ ! -z "$(docker --version)" ]; then			
			echo "INFO: Found docker version $(docker --version) ..."
			echo "INFO: DOCKER IS ALREADY INSTALLED!"
			return 0
		fi			
	fi
}

dockerInstallSSH() {
	local RC=1
	local DOCKER_IMAGE_NAME="vaxiomGCE/AXIOSSH01"
	
	if ( ! does_file_exists "$DOCKERFILE_SSH" )
	then
		echo "ERROR:  Unable to locate dockerfile:  $DOCKERFILE_SSH!!!!"		
		return $RC
	else
		cat $DOCKERFILE_SSH > Dockerfile		
		if [ $? -eq 0 ];then	   		
			docker build -t "$DOCKER_IMAGE_NAME" .
			if [ $? -eq 0 ];then	   			
				echo "INFO:  Docker image build submitted successfully."
				echo "INFO: Run this command to see list of images: docker images"
				echo "INFO: Run this command to see running images: docker ps"
				echo "INFO: Run this command to attach to image shell: docker run -t -i -p 0.0.0.0:9122:22 -p 0.0.0.0:10389:10389 vaxiomGCE/AXIOSSH01 /bin/bash"
				RC=0
			else
				echo "ERROR:  Error running=> docker build -t $DOCKER_IMAGE_NAME ."
			fi
		else
			echo "ERROR:  Error running=> docker build -t $DOCKER_IMAGE_NAME ."
		fi
	fi
	
	if ( does_file_exists "Dockerfile" )
	then
		rm -f Dockerfile
	fi
	
	return $RC
}

wrapUp() {
	cd $HOME_DIR
	echo "INFO: Complete!"
}

### Main paragraph ####
main() {
	local RC=1

	if ( usage )
	then
		if ( dockerExists )
		then
			if ( dockerInstallSSH )
			then
				RC=0				
			fi
		fi
	fi
	
	if [ $RC -eq 0 ];then
		echo "SUCCESS: script Completed Successfully!  See logs..."
	else
		echo "ERROR: script did not complete successfully!  See logs..."
	fi
	
	return $RC
}

main
wrapUp



#### NOTES #####
### Usage:   docker build -t "vaxiomGCE/AXIOSSH01" . > Dockfile_4_InstallSSH.log &
###	  docker build -t "vaxiomGCE/AXIOSSH01" - < Dockfile_4_InstallSSH.txt > Dockfile_4_InstallSSH.log &
###	  docker run -t -i -p 0.0.0.0:9122:1023 vaxiomGCE/AXIOSSH01 /bin/bash
###	  docker run -t -i -p 0.0.0.0:9122:22 vaxiomGCE/AXIOSSH01 /bin/bash
### 	  docker run -d -p 0.0.0.0:9122:22 vaxiomGCE/AXIOSSH01
###	  docker run -rm -P -name ssh_container eg_postgresql
### 	  docker run -i -t -p 0.0.0.0:9122:22 vaxiomGCE/AXIOSSH01 /bin/bash
#####	  docker run -d -p 9122:22 -p 80:8080 -p 8443:8443 -p 443:443 -v  /opt/vaxiomGCE_AXIOVM01TOMCAT7 vaxiomGCE/AXIOVM01TOMCAT7
###FROM centos:latest
