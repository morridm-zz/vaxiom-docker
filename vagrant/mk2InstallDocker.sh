#!/usr/bin/env bash
set -e
HOME_DIR=`pwd`
VAXIOM_GIT_HOME="/tmp/vaxiom_docker/"
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

installGit() {
	local RC=1
	yum -y install git
	if [ $? -eq 0 ];then	   	   
		RC=0
	else
		echo "ERROR:  Unable to generate rsa keys:  ssh-keygen -q -N '' -t rsa -f $gsRSA_KEY"
	fi			
	
	return $RC
}


installFedoraPkgr() {
	echo "Install fedora-packager..."
	yum -y install fedora-packager
	return 0
}

# Installs the http://Docker.io package
installDocker() {
	local RC=1
	echo "INFO: Installing docker:  yum -y install docker-io"
	yum -y install docker-io
	if [ $? -eq 0 ];then	   	   
		chkconfig docker on
		RC=0
	else
		echo "ERROR:  Unable to install docker using:  yum -y install docker-io"
	fi			
	
	return $RC
}

# Verify all rpm packages are current
runYumUpdate() {
	echo "INFO: Checking current installation: yum -y update..."
	###installFedoraPkgr
	yum -y update
	return 0
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
		chmod 777 $VAXIOM_GIT_HOME
	fi
	
	cd $VAXIOM_GIT_HOME
	git clone https://github.com/morridm/vaxiom-docker.git
	if [ $? -eq 0 ];then	   	   
		RC=0
	else
		echo "ERROR:  Unable to install docker using:  yum -y install docker-io"
	fi
	
	cd $TMP_HOME_DIR
	return $RC
}

# This is the main function 
main() {
	echo "INFO: Verifying installation steps..."

	runYumUpdate

	if ( isCorrectKernel ) 
	then 
		if ( ! dockerExists )
		then
			if ( installGit )
			then
				if ( installVaxiomDocker )
				then
					installDocker
					DOCKER_VERSION=$(docker --version)
					if [ -z "$DOCKER_VERSION" ]; then
						echo "ERROR: DOCKER NOT SUCCESSFULLY INSTALLED!"
					else								
						echo "INFO: DOCKER VERSION $DOCKER_VERSION SUCCESSFULLY INSTALLED!"
						echo "INFO: Reboot then run 'sudo service docker start' to start the Docker.io service manually..."
					fi
				fi
			fi
		fi
	fi
	
	#if ( ! does_file_exists "/etc/ssh/docker_host_rsa_key" )
	#then
	#	generateSSHKeys
	#	updateNetworkSettings
	#fi
	
	echo "INFO: Complete!"
}

####### MAIN #######
main
