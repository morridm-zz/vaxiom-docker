#!/usr/bin/env bash
set -e

#Command-line arguments
repo="$1"
distro="$2"
mirror="$3"

#Variables
HOME_DIR=`pwd`
DEFAULT_MIRROR="http://mirror.centos.org/centos/6/os/x86_64/Packages/"


### Usage example: "./mk3BaseCentOsImage.sh vaxiomGCE/AXIOM01CENTOS65 centos-6 http://mirror.centos.org/centos/6/os/x86_64/Packages/"
usage() {
	if [ ! "$repo" ] || [ ! "$distro" ]; then
		self="$(basename $0)"
		echo >&2 "usage: $self repo distro [mirror]"
		echo >&2 "   e.g.,: mk3BaseCentOsImage.sh vaxiomGCE/AXIOM01CENTOS65 centos-6 http://mirror.centos.org/centos/6/os/x86_64/Packages/"
		echo >&2 
		echo >&2 "   e.g., $self username/centos centos-5"
		echo >&2 "       $self username/centos centos-6"
		echo >&2
		echo >&2 "   e.g., $self username/slc slc-5"
		echo >&2 "       $self username/slc slc-6"
		echo >&2
		echo >&2 "   e.g., $self username/centos centos-5 http://vault.centos.org/5.8/os/x86_64/CentOS/"
		echo >&2 "       $self username/centos centos-6 http://vault.centos.org/6.3/os/x86_64/Packages/"
		echo >&2
		echo >&2 'See /etc/rinse for supported values of "distro" and for examples of'
		echo >&2 '  expected values of "mirror".'
		echo >&2
		echo >&2 'This script is tested to work with the original upstream version of rinse,'
		echo >&2 '  found at http://www.steve.org.uk/Software/rinse/ and also in Debian at'
		echo >&2 '  http://packages.debian.org/wheezy/rinse -- as always, YMMV.'
		echo >&2
		return 1
	else
		return 0
	fi
}


saveNewDockerImage() {
	echo "INFO: Searching for the new 'vaxiomGCE/AXIOM01CENTOS65' image..."
	local DOCKER_DATE=$(date +%d%m%Y%I%M%S)
	local DOCKER_IMAGES_STR=$(docker images | grep 'vaxiomGCE/AXIOM01CENTOS65' | sed 's/  */\ /g')
	declare -a DOCKER_IMAGE_ARRAY=($DOCKER_IMAGES_STR)
	local DOCKER_IMAGE_REPO=${DOCKER_IMAGE_ARRAY[0]}
	local DOCKER_IMAGE_TAG=${DOCKER_IMAGE_ARRAY[1]}
	local DOCKER_IMAGE_ID=${DOCKER_IMAGE_ARRAY[2]}
	local DOCKER_IMAGE_NAME=$(echo $DOCKER_IMAGE_REPO | sed 's/\//\_/g')
	local DOCKER_IMAGE_FILENAME="${DOCKER_IMAGE_NAME}_${DOCKER_DATE}.tar"
	
	echo "INFO: Saving docker image: $DOCKER_IMAGE_REPO using imageId: $DOCKER_IMAGE_ID to file:  $DOCKER_IMAGE_FILENAME"
	if [ -z "$DOCKER_IMAGE_ID" ]; then
	        echo "ERROR:  Unable to find docker image $DOCKER_IMAGE_REPO"
	        return 1
	else
	        echo "INFO: Docker image id $DOCKER_IMAGE_ID found.  Saving to disk as $DOCKER_IMAGE_FILENAME ...."
	        docker save $DOCKER_IMAGE_ID > $DOCKER_IMAGE_FILENAME
	        xz -z $DOCKER_IMAGE_FILENAME
	        return 0
	fi
}

dockerIsInstalled() {
	local DOCKER_VERSION=$(docker --version | grep -e '^Docker')
	if [ -z "$DOCKER_VERSION" ]; then
		echo "ERROR: Docker was not found!!! ..."
		echo "ERROR: DOCKER NOT SUCCESSFULLY INSTALLED!"
		echo "ERROR: Install Docker.io first, then try again..."
		return 1
	else
		echo "INFO: Found docker version $DOCKER_VERSION ..."
		if [ -z "$(service docker status | grep 'running')" ];then
			service docker start
		else
			service docker restart
		fi
		return 0
	fi	
}


rinseIsInstalled() {
	if ! builtin type -p rinse &>/dev/null; then
		return 1
	else
		return 0
	fi

}

installRinse() {
	echo "INFO: Installing Rinse 2.0.1..."
	cd /opt
	wget http://www.steve.org.uk/Software/rinse/rinse-2.0.1.tar.gz
	tar xvfz rinse-2.0.1.tar.gz
	rm -f rinse-2.0.1.tar.gz
	cd rinse-2.0.1
	make install
}

installDependencies() {
	echo "INFO: Installing dependencies..."
	######yum -y install perl rpm rpm2cpio perl-libwww-perl which wget xz
	
	echo "INFO:	Installing perl..."
	yum -y install perl perl-libwww-perl
	
	echo "INFO:	Installing rpm..."
	yum -y install rpm rpm2cpio
	
	echo "INFO:	Installing which..."
	yum -y install which
	
	echo "INFO:	Installing wget..."
	yum -y install wget
	
	echo "INFO:	Installing xz compression tool..."
	yum -y install xz
	
	echo "INFO:     Installing nc network tool...."
	yum -y install nc

	echo "INFO: Checking for rinse 2.0.1..."
	if ( rinseIsInstalled )
	then
		echo "INFO: Rinse version $(rinse --version) found...."
		return 0
	else
		installRinse		
		if ( rinseIsInstalled )
		then
			return 0
		else
			return 1
		fi
	fi
}

dependenciesAreInstalled() {
	if ! builtin type -p xz &>/dev/null; then
		echo "ERROR: xz compression tool not found..."
		return 1
	else
		echo "INFO: xz version: " `xz --version` " was found..."
	fi

	if ! builtin type -p rinse &>/dev/null; then
		echo "ERROR: Rinse 2.0.1 not found!"
		return 1
	else
		echo "INFO: rinse version: " `rinse --version` " was found..."
	fi
	
	return 0
}

destroyOldDockerImages() {
	echo "INFO: DELETING EXISTING DOCKER CONTAINERS..."
	for container in `docker ps -a -q`; do
		echo "INFO: Deleting container: $container ..."
	  	docker rm -f $container
	done

	echo "INFO: DELETING EXISTING DOCKER IMAGES..."
	for image in `docker images -q`; do
	  	echo "INFO: Deleting container: $image ..."
	  	docker rmi -f $image
	done
	
	return 0
}

importNewDockerImage() {
	local repository="$1"
	local imageversion="$2"
	sudo tar --numeric-owner -c . | docker import - $repository:$imageversion
	echo "INFO: Importing the new image to docker using command: docker import - $repository:$imageversion"
	docker run -i -t $repository:$imageversion echo success
	
	return 0
}

createBaseLinuxImage() {
	local target="/tmp/docker-rootfs-rinse-$distro-$$-$RANDOM"

	cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
	returnTo="$(pwd -P)"

	local rinseArgs=( --arch amd64 --distribution "$distro" --directory "$target" )
	if [ "$mirror" ]; then
		rinseArgs+=( --mirror "$mirror" )
	else
		echo "INFO: Mirror not found... Using default: $DEFAULT_MIRROR"
		rinseArgs+=( --mirror "$DEFAULT_MIRROR" )
	fi

	set -x

	mkdir -p "$target"

	sudo rinse "${rinseArgs[@]}"

	cd "$target"

	sudo rm -rf dev
	sudo mkdir -m 755 dev
	(
		cd dev
		sudo ln -sf /proc/self/fd ./
		sudo mkdir -m 755 pts
		sudo mkdir -m 1777 shm
		sudo mknod -m 600 console c 5 1
		sudo mknod -m 600 initctl p
		sudo mknod -m 666 full c 1 7
		sudo mknod -m 666 null c 1 3
		sudo mknod -m 666 ptmx c 5 2
		sudo mknod -m 666 random c 1 8
		sudo mknod -m 666 tty c 5 0
		sudo mknod -m 666 tty0 c 4 0
		sudo mknod -m 666 urandom c 1 9
		sudo mknod -m 666 zero c 1 5
	)

	sudo rm -rf usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
	sudo rm -rf usr/share/{man,doc,info,gnome/help}
	sudo rm -rf usr/share/cracklib
	sudo rm -rf usr/share/i18n
	sudo rm -rf var/cache/yum
	sudo mkdir -p --mode=0755 var/cache/yum
	sudo rm -rf sbin/sln
	sudo rm -rf etc/ld.so.cache var/cache/ldconfig
	sudo mkdir -p --mode=0755 var/cache/ldconfig
	echo 'NETWORKING=yes' | sudo tee etc/sysconfig/network > /dev/null

	local version=
	if [ -r etc/redhat-release ]; then
		version="$(sed -E 's/^[^0-9.]*([0-9.]+).*$/\1/' etc/redhat-release)"
	elif [ -r etc/SuSE-release ]; then
		version="$(awk '/^VERSION/ { print $3 }' etc/SuSE-release)"
	fi

	if [ -z "$version" ]; then
		echo >&2 "warning: cannot autodetect OS version, using $distro as tag"
		sleep 20
		version="$distro"
	fi

	importNewDockerImage "$repo" "$version"

	cd "$returnTo"
	sudo rm -rf "$target"
	
	return 0
}

wrapUp() {
	cd $HOME_DIR
	echo "INFO: Complete!"
}

### Main paragraph ####
main() {
	if ( ! usage )
	then		
		return 1
	else
		if ( dockerIsInstalled )
		then
			installDependencies		

			cd $HOME_DIR

			if ( dependenciesAreInstalled )
			then
				destroyOldDockerImages
				createBaseLinuxImage
				saveNewDockerImage							
			fi								
		fi
	fi
	
	wrapUp
	return 0
}

main