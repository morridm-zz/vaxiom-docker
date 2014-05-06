#!/usr/bin/env bash
set -e
HOME_DIR=`pwd`
DEFAULT_GIT_LIBRARY="https://github.com/morridm/vaxiom-docker.git"
DEFAULT_VAXIOM_GIT_HOME="/opt/vaxiom-docker"
VAXIOM_GIT_HOME="$1"
GIT_LIBRARY="$2"

if [ -z "$VAXIOM_GIT_HOME" ];then			
	VAXIOM_GIT_HOME="$DEFAULT_VAXIOM_GIT_HOME"
	echo "INFO:  	Setting temporary install directory to $VAXIOM_GIT_HOME"
fi

if [ -z "$GIT_LIBRARY" ];then			
	GIT_LIBRARY="$DEFAULT_GIT_LIBRARY"
	echo "INFO:  	Setting git library to $GIT_LIBRARY"
fi

does_file_exists(){
	local f="$1"
	[[ -f "$f" ]] && return 0 || return 1
}

clearDockerImages() {
	local RC=0
	local iRunningContainers=$(docker ps -q | wc -l)
	local iContainers=$(docker ps -a -q | wc -l)
	local iImages=$(docker images -a -q | wc -l)
	
	if [[ $RC -eq 0 && $iRunningContainers -gt 0 ]];then
		echo "INFO: Stopping containers: $(docker ps)"
		docker stop $(docker ps -q)
		if [ ! $? -eq 0 ];then
			RC=1
		fi
	fi
	
	if [[ $RC -eq 0 && $iContainers -gt 0 ]];then
		echo "INFO: Removing containers: $(docker ps -a)"
		docker rm $(docker ps -a -q)
		if [ ! $? -eq 0 ];then
			RC=1
		fi
	fi

	if [[ $RC -eq 0 && $iImages -gt 0 ]];then
		echo "INFO: Removing images: $(docker images -a)"
		docker rmi $(docker images -a -q)
		if [ ! $? -eq 0 ];then
			RC=1
		fi
	fi
	
	if [ ! $RC -eq 0 ];then
		echo "WARNING: Unable to remove existing docker images!"
	fi
	
	return 0
}

createDirectory() {
	local RC=0
	local dirName="$1"
	
	if [ -d "$dirName" ];then
		echo "Deleting existing $dirName directory:  sudo rm -rf $dirName"
		sudo rm -rf $dirName
		if [ ! $? -eq 0 ];then
			RC=1
			echo "ERROR: Executing cmd: sudo rm -rf $dirName"
		fi
	fi
	
	if [ $RC -eq 0 ];then
		sudo mkdir -p $dirName
		if [ $? -eq 0 ];then
			sudo chmod 777 $dirName
			if [ ! $? -eq 0 ];then
				echo "ERROR: Executing cmd: sudo chmod 777 $dirName"
			fi
		else
			echo "ERROR: Executing cmd: sudo mkdir -p $dirName"
		fi
	fi
	
	return $RC
}

installVaxiomDocker() {
	local RC=1
	local TMP_HOME_DIR=`pwd`

	echo "INFO: Installing $GIT_LIBRARY ..."
	if ( createDirectory "$VAXIOM_GIT_HOME" )
	then
		cd $VAXIOM_GIT_HOME
		if [ $? -eq 0 ];then	   	   
			cd ..
			if [ $? -eq 0 ];then	   	   
				sudo git clone $GIT_LIBRARY
				if [ $? -eq 0 ];then	   	   
					RC=0
				else
					echo "ERROR:  Unable to run cmd: git clone $GIT_LIBRARY"
				fi			
			else
				echo "ERROR:  Unable to run cmd: cd .."
			fi			
		else
			echo "ERROR:  Unable to run cmd: cd $VAXIOM_GIT_HOME"
		fi
	else
		echo "ERROR: Unable to install $GIT_LIBRARY!!!"
	fi
	
	if [[ $RC=0 && -d "$VAXIOM_GIT_HOME" ]];then
		sudo find $VAXIOM_GIT_HOME -iname "*.sh" | sudo xargs chmod +x
		sudo chown -R $USER:$USER "$VAXIOM_GIT_HOME"
		if [ ! $RC -eq 0 ];then
			echo "ERROR: running cmd:  find $VAXIOM_GIT_HOME -iname "*.sh" | xargs chmod +x"
		fi
	fi
	
	cd $TMP_HOME_DIR
	return $RC
}

wrapUp() {
    cd $HOME_DIR
}


main() {
	local RC=1

	clearDockerImages
	if ( installVaxiomDocker )
	then
		RC=0
	fi
	
	return $RC
}

main
wrapUp
