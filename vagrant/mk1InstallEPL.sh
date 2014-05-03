#!/usr/bin/env bash
set -e
HOME_DIR=`pwd`

# Verify all rpm packages are current
runYumUpdate() {
	echo "INFO: Checking current installation: yum -y update..."
	yum -y update
	return 0
}

installEpel() {
	echo "INFO: Detecting current kernel..."
	local GRUB_CONF_FILE="/boot/grub/grub.conf"
	local GRUB_ELREPO_VERSION="3.14.1-1.el6.elrepo.x86_64"
	local GRUB_BOOT_VERSION=$(cat /boot/grub/grub.conf | grep -e '^title CentOS' | head -1 | grep -e '^title CentOS (3.14' | cut -s --delimiter='(' --fields=2 | sed 's/)//g')
	local GRUB_BOOT_DEFAULT_VALUE=$(cat /boot/grub/grub.conf | grep -e '^default=')
	local GRUB_BOOT_DEFAULT_ZERO=$(cat /boot/grub/grub.conf | grep -e '^default=0')

	echo "INFO: Detected current kernel as: $GRUB_BOOT_VERSION"
	echo "INFO:  Checking grub boot verson...."
	if [ -z "$GRUB_BOOT_VERSION" ];then
		echo "INFO: Configuring the extra packages for RedHat/CentOS EPEL Repository: yum -y install http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
		yum -y install http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

		echo "INFO: Verifing/Upgrading elrepo to kernel 6.5: yum -y install http://mirror.symnds.com/distributions/elrepo/elrepo/el6/x86_64/RPMS/elrepo-release-6-5.el6.elrepo.noarch.rpm"
		yum -y install http://mirror.symnds.com/distributions/elrepo/elrepo/el6/x86_64/RPMS/elrepo-release-6-5.el6.elrepo.noarch.rpm

		echo "Installing the new kernel: yum -y --enablerepo=elrepo-kernel install kernel-ml"
		yum -y --enablerepo=elrepo-kernel install kernel-ml
		
		#echo "INFO:  Replacing $GRUB_BOOT_DEFAULT_VALUE with default=0 in $GRUB_CONF_FILE"
		#cp -fu $GRUB_CONF_FILE /boot/grub/grub.conf_bkp
		#sed -i 's/$GRUB_BOOT_DEFAULT_VALUE/default=0/g' $GRUB_CONF_FILE	

		echo "WARNING: Reboot server using cmd: shutdown -r +1"
		echo "WARNING: RUN SCRIPT AGAIN AFTER REBOOT!!!"
		echo "WARNING: Don't forget to check /boot/grub/grub.conf to make sure the correct images is booted."
		###echo "WARNING: Add line selinux=0 to your /boot/grub/grub.conf file..."
		echo "WARNING:  After reboot run:"
		echo "			1. vi /etc/sysconfig/selinux"
		echo "			2. Change 'SELINUX=enforcing' to 'SELINUX=disabled' "
		echo "          3. reboot"
	fi
}

main() {
	runYumUpdate
	installEpel
}


main