#!/usr/bin/env bash
set -e
HOME_DIR=`pwd`
DEFAULT_VAXIOM_GIT_HOME="/opt/vaxiom-docker/"
DEFAULT_AUTHORIZED_KEYS="/home/vagrant/.ssh/authorized_keys"

CREATE_USERNAME="$1"
CREATE_USERNAME_PWD="$1"
AUTHORIZED_KEYS="$2"
VAXIOM_GIT_HOME="$3"

if [ -z "$VAXIOM_GIT_HOME" ];then			
	VAXIOM_GIT_HOME="$DEFAULT_VAXIOM_GIT_HOME"
	echo "INFO:  	Setting temporary install directory to $VAXIOM_GIT_HOME"
fi

if [ -z "$AUTHORIZED_KEYS" ];then
	AUTHORIZED_KEYS="$DEFAULT_AUTHORIZED_KEYS"
	echo "INFO:  	Defaulting keys file location to $AUTHORIZED_KEYS"
fi


usage() {
        local RC=0
		
		if [ -z "$CREATE_USERNAME" ];then
			RC=1
		fi
		
		echo "INFO: Running with arguments: $CREATE_USERNAME, $AUTHORIZED_KEYS, $VAXIOM_GIT_HOME ..."
		if [ ! $RC -eq 0 ];then
			echo "INFO:  Usage:  $(basename $0) <required: docker username to create> <optional: authorized key file> <optional: vaxiom-docker.git install directory>"
			echo "INFO:  Usage example 1:  $(basename $0) svc_docker"
			echo "INFO:  Usage example 2:  $(basename $0) svc_docker $DEFAULT_AUTHORIZED_KEYS "
			echo "INFO:  Usage example 3:  $(basename $0) svc_docker $DEFAULT_AUTHORIZED_KEYS $DEFAULT_VAXIOM_GIT_HOME"
		fi
		
        return $RC
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
		return 1
	else
		if [ ! -z "$(docker --version)" ]; then			
			echo "INFO: Found docker version $(docker --version) ..."
			echo "INFO: DOCKER IS ALREADY INSTALLED!"
			return 0
		fi			
	fi
}

runYumInstall() {
	local RC=1
	local pkg="$1"

	echo "INFO:  Installing package $pkg ..."
	if [ ! -z "$pkg" ];then
		yum -y install "$pkg"
		if [ $? -eq 0 ];then	   	   
			RC=0
		fi			
	fi
	
	if [ ! $RC -eq 0 ];then
		echo "ERROR:  Unable to install git: yum -y install $pkg"
	fi
	
	return $RC
}

runYumUpdate() {
	echo "INFO: Checking current installation: yum -y update..."
	yum -y update
	return 0
}

installGit() {
	runYumInstall "git"
	return $?
}

installBridgeUtils() {
	runYumInstall "bridge-utils"
	return $?
}

installFedoraPkgr() {
	runYumInstall "fedora-packager"
	return $?
}

installDocker() {
	runYumInstall "docker-io"
	return $?
}

# Verify elrepo is installed and running docker compatible kernel
isCorrectKernel() {
	local GRUB_CONF_FILE="/boot/grub/grub.conf"
	if ( ! does_file_exists "$GRUB_CONF_FILE" )
	then
		echo "ERROR:  $GRUB_CONF_FILE not found! Installation failed!"
		return 1
	else
		echo "INFO: Found $GRUB_CONF_FILE..."
		local GRUB_ELREPO_VERSION="3.14.1-1.el6.elrepo.x86_64"
		local GRUB_BOOT_VERSION=$(cat /boot/grub/grub.conf | grep -e '^title CentOS' | head -1 | grep -e '^title CentOS (3.14' | cut -s --delimiter='(' --fields=2 | sed 's/)//g')
		local GRUB_BOOT_DEFAULT_VALUE=$(cat /boot/grub/grub.conf | grep -e '^default=')
		local GRUB_BOOT_DEFAULT_ZERO=$(cat /boot/grub/grub.conf | grep -e '^default=0')

		echo "INFO: Detected current kernel as: $GRUB_BOOT_VERSION"
		if [ -z "$GRUB_BOOT_VERSION" ];then
			echo "ERROR:  Incompatible kernel found.  Please update kernel.  See mk1InstallEPL.sh script."
			return 1
		else 
			return 0
		fi	
	fi
}

# Starts the docker service/daemon
startDockerDaemon() {
	service docker start
	return 0
}

installVaxiomDocker() {
	local RC=1
	local TMP_HOME_DIR=`pwd`
	
	if [ ! -d "$VAXIOM_GIT_HOME" ];then		
		sudo mkdir -p $VAXIOM_GIT_HOME
		if [ $? -eq 0 ];then
			chmod 777 $VAXIOM_GIT_HOME
			if [ $? -eq 0 ];then
				cd $VAXIOM_GIT_HOME
				cd ..
				git clone https://github.com/morridm/vaxiom-docker.git
				if [ $? -eq 0 ];then	   	   
					RC=0
				else
					echo "ERROR:  Unable to run cmd: git clone https://github.com/morridm/vaxiom-docker.git"
				fi
			fi
		fi
	else
		RC=0
	fi
	
	cd $TMP_HOME_DIR
	return $RC
}

createMyUserAccount() {
	local RC=0
	
	if [ ! -f "$AUTHORIZED_KEYS" ];then
		echo "ERROR:  unable to locate the authorized keys at file location: $AUTHORIZED_KEYS"
		return 1
	fi
	
	useradd -m $CREATE_USERNAME
	if [ ! $? -eq 0 ];then	   	   
		echo "ERROR:  running command:  useradd -m $CREATE_USERNAME"
		return 1
	fi
	
	echo "$CREATE_USERNAME:$CREATE_USERNAME_PWD" | chpasswd
	if [ ! $? -eq 0 ];then	   	   
		echo "ERROR:  running command:  echo "$CREATE_USERNAME:$CREATE_USERNAME_PWD" | chpasswd"
		return 1
	else 
		echo "WARNING:  Created user $CREATE_USERNAME with password $CREATE_USERNAME_PWD.  PLEASE CHANGE PASSWORD AFTER 1st LOGIN!!!"
	fi
	
	mkdir -p /home/$CREATE_USERNAME/.ssh/
	if [ ! $? -eq 0 ];then	   	   
		echo "ERROR:  running command:  mkdir -p /home/$CREATE_USERNAME/.ssh/"
		return 1
	fi
	
	chown -R $CREATE_USERNAME:$CREATE_USERNAME /home/$CREATE_USERNAME/.ssh/
	
	###DEFAULT_AUTHORIZED_KEYS="/home/vagrant/.ssh/authorized_keys"
	echo "INFO: Running cmd: cat $AUTHORIZED_KEYS >> /home/$CREATE_USERNAME/.ssh/authorized_keys"
	cat $AUTHORIZED_KEYS >> /home/$CREATE_USERNAME/.ssh/authorized_keys
	echo "$CREATE_USERNAME        ALL=(ALL)       ALL" >> /etc/sudoers.d/$CREATE_USERNAME
	chmod 700 /home/$CREATE_USERNAME/.ssh
	chown $CREATE_USERNAME:$CREATE_USERNAME /home/$CREATE_USERNAME/.ssh/authorized_keys
	chmod 600 /home/$CREATE_USERNAME/.ssh/authorized_keys
	
	return $RC
}

wrapUp() {
	cd $HOME_DIR
}

# This is the main function 
main() {
	local RC=1
	
	if ( usage )
	then
		runYumUpdate
		if ( createMyUserAccount ) 
		then 
			if ( isCorrectKernel ) 
			then 
				if ( ! dockerExists )
				then
					if ( installGit )
					then
						if ( installBridgeUtils )
						then
							if ( installVaxiomDocker )
							then
								installDocker
								DOCKER_VERSION=$(docker --version)
								if [ -z "$DOCKER_VERSION" ]; then								
									echo "ERROR: DOCKER NOT SUCCESSFULLY INSTALLED!"
								else							
									echo "INFO: Adding $CREATE_USERNAME to docker group."
									usermod -a -G docker $CREATE_USERNAME
									chown -R $CREATE_USERNAME:$CREATE_USERNAME $VAXIOM_GIT_HOME
									echo "INFO: DOCKER VERSION $DOCKER_VERSION SUCCESSFULLY INSTALLED!"
									echo "INFO: Reboot then run 'sudo service docker start' to start the Docker.io service manually..."
									RC=0
								fi
							fi
						fi
					fi
				fi
			fi	
		fi
	fi
	echo "INFO: Complete!"
}

####### MAIN #######
main
wrapUp