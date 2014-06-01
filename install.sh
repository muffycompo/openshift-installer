#!/bin/bash
############################################################################
# OpenShift Easy Install Script - This script makes it incredibly easy to deploy
# OpenShift Origin on your server by removing the need to install dependencies
# manually or perform any preliminary configurations on your server. It is safest
# to use this install script on a clean install of your desired distro.
#
#  See the README for more details.
#
#
# (C) Copyright 2014 Ryan Leaf. This program is licensed under the GNU General
# Public License (GPLv3). You are bound by the terms of the license. You may find
# a copy of the license included in this repository or you may find a copy of the
# license at <http://www.gnu.org/licenses/>. 
###############################################################################


# Check if the user is running as root.
if [[ $EUID -ne 0 ]]; then
	echo "Failing. This script must be run as 'root'. Please try again."
	exit 1
fi


# Get the desried hostname from the user.
hostname_input()
{
	echo -e -n "\nPlease enter the hostname that you wish to use.  "
	read  user_hostname
	echo -e -n "You chose" $user_hostname "is that correct? [y/n] "
	read  hostname_bool

	if [ $hostname_bool == "y" ]; then
		stage1
	elif [ $hostname_bool == "n" ]; then
		hostname_input
	else
		hostname_input
	fi
}

############# DISTROS #############
fedora()
{
	# Check version of Fedora. If not 19 or 20, then quit.
	releasenum=`cat /etc/fedora-release | awk {'print $3'}`
	if [ $releasenum == "20" ]; then
		sudo yum -y remove firewalld # Required removal for Fedora 20.
	elif [ $releasenum == "19" ]; then
		: #NOP
	else
		echo "You're running an incompatible version of Fedora."
		exit 1
	fi

	# Update the OS:
	yum -y update

	# Install dependencies:
	yum -y install ruby unzip augeas httpd-tools puppet bind

	# Fix SELinux settings so they are enforcing instead of disabled.

	echo > /etc/selinux/config  # Clear the file.
	echo -e "SELINUX=enforcing\nSELINUXTYPE=targeted" > /etc/selinux/config # Enable enforcing.

	# Change the user's hostname.
	echo $user_hostname > /etc/hostname
	hostname $user_hostname

	echo "Successfully prepped your Fedora system."
}

centos()
{
	# Check version of CentOS.

	# Add OpenShift repos.
	touch /etc/yum.repos.d/openshift-origin-deps.repo
	touch /etc/yum.repos.d/openshift-origin.repo
	echo -e "[openshift-origin-dep]\nname=openshift-origin-deps\nbaseurl=http://mirror.openshift.com/pub/origin-server/release/3/rhel-6/dependencies/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/openshift-origin-deps.repo
	echo -e "[openshift-origin]\nname=openshift-origin\nbaseurl=http://mirror.openshift.com/pub/origin-server/release/3/rhel-6/packages/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/openshift-origin.repo

	# Add EPEL repos.
	sudo yum -y install http://download.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm


	# Update the OS:
	yum -y update

	# Install dependencies:
	yum -y install ruby193 unzip curl scl-utils httpd-tools puppet bind bind-utils augeas
	#yum -y install activemq activemq-client


	# Configure SELinux settings. This is not necessary for all hosts, but
	# some hosts disable SELinux by default.

	echo > /etc/selinux/config # Clear the config file.
	echo -e "SELINUX=enforcing\nSELINUXTYPE=targeted" > /etc/selinux/config # Enable enforcing.

	# Change the user's hostname.
	echo $user_hostname > /etc/hostname
	hostname $user_hostname

	echo "Succesfully prepped your CentOS system."
}

redhat()
{
	echo "You're running RHEL, but I can't do a thing."
}

debian()
{
	# Update repos
	apt-get update

	# Install updates
	apt-get dist-upgrade -y

	# Install dependencies:
	apt-get install ruby unzip curl scl-utils httpd-tools puppet bind bind-utils augeas
	apt-get install activemq activemq-client

	# NEED TO DO SOMETHING TO GET SELINUX ENABLED AND CONFIGURED.

	# Configure SELinux settings.
	echo "You're running Debian..."
}

distro()
{
	distroname=`cat /etc/*-release | awk 'NR==1{print $1}'`

	if [[ $distroname == *"Debian"* ]]; then
		echo "Looks like you're running Debian."
	elif [[ $distroname == *"Fedora"* ]]; then
		echo -e "Looks like you're running Fedora.\n"
		fedora
	elif [[ $distroname == *"CentOS"* ]]; then
		echo "Looks like you're running CentOS."
		centos
	elif [[ $distroname == *"Red Hat"* ]]; then
		echo "Looks like you're running Red Hat."
	else
		echo "Either you're running an incompatible distro or you don't have a release file."
	fi

}
######### Stage 1 ############
stage1()
{
	distro

	# Finishing
	echo "Done with phase 1. About to reboot."

	touch .LOCK_SLE # Create a lock.
	reboot
	exit 0 # Make sure this script doesn't go through 
}

######### Stage 2 ###########
stage2()
{
	echo "PHASE 2: Now installing OpenShift. "
	sh <(curl -s https://install.openshift.com/)

	rm -Rf .LOCK_SLE
	echo "Script is finished."
	reboot
	exit 0
}
# First run
if [ ! -f ".LOCK_SLE" ]; then
	# Initial info block.
	echo "Welcome to the OpenShift Origin install script for Fedora. This script is known to work on Fedora 19 and 20. "
	echo "During this install, your computer will reboot. Please hit Ctrl+C if you're computer is not ready to be restarted. "
	echo "After rebooting, you will need to relaunch this script. I will ask you a few questions to help you install Origin on your server."
	hostname_input
fi

# Second run
if [ -f ".LOCK_SLE" ]; then
	stage2
fi
