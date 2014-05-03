#!/usr/bin/env bash
set -e
HOME_DIR=`pwd`

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

generateSSHKeys() {
	#cut -d: -f1 /etc/passwd | grep "$USR" > /dev/null
	
	local gsRSA_KEY="/etc/ssh/ssh_host_rsa_key"
	local gsRSA_KEY_PUB="/etc/ssh/ssh_host_rsa_key.pub"
	
	echo "INFO:  Generating ssh keys: ssh-keygen -q -N '' -t rsa -f $gsRSA_KEY"
	if ( ! does_file_exists "$gsRSA_KEY" )
	then
		ssh-keygen -q -N "" -t rsa -f "$gsRSA_KEY"
		if [ ! $? -eq 0 ];then	   
		   echo "ERROR:  Unable to generate rsa keys:  ssh-keygen -q -N '' -t rsa -f $gsRSA_KEY"
		   return 1
		fi		
	fi
	
	if [ ! -d "/home/vagrant/docker" ];then
		mkdir -p /home/vagrant/docker
	fi
	
	if ( ! does_file_exists "$gsRSA_KEY" )
	then
		echo "ERROR: Unable to locate $gsRSA_KEY!!!"
		return 1
	else 
		chmod 700 /etc/ssh/
		chmod 600 /etc/ssh/ssh_host_rsa_key
		cat /etc/ssh/ssh_host_rsa_key.pub >> /home/vagrant/docker/authorized_keys
		chmod 700 /home/vagrant/docker/
		chmod 600 /home/vagrant/docker/authorized_keys
		chown -R vagrant:vagrant /home/vagrant/docker
		chown vagrant:vagrant /home/vagrant/docker/authorized_keys
		return 0
	fi
}

updateNetworkSettings() {
	echo "INFO:  Updating network settings..."
	grep ^net.ipv4.ip_forward /etc/sysctl.conf > /dev/null 2>&1 && \
    sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf  || \
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
	
	echo "INFO:  Updated network settings are:"
	sysctl -p
	
	if [ -z "$(grep selinux=0 /boot/grub/menu.lst)" ];then
		echo "selinux=0" >> /boot/grub/grub.conf
	fi
	
	# Turn off your default firewall rules for now
	service iptables stop
	chkconfig iptables off
	
	return 0
}

# Starts the docker service/daemon
startDockerDaemon() {
	service docker start
	return 0
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
	
	#if ( ! does_file_exists "/etc/ssh/docker_host_rsa_key" )
	#then
	#	generateSSHKeys
	#	updateNetworkSettings
	#fi
	
	echo "INFO: Complete!"
}

####### MAIN #######
main
