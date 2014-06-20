#!/bin/bash
###################################################################################
# OpenShift Easy Install Script - This script makes it incredibly easy to deploy  #
# OpenShift Origin on your server by removing the need to install dependencies    #
# manually or perform any preliminary configurations on your server. It is safest # 
# to use this install script on a clean install of your desired distro.           #
#                                                                                 #
#  See the README for more details.                                               #
#                                                                                 #
#                                                                                 #
# (C) Copyright 2014 Ryan Leaf. This program is licensed under the GNU General    #
# Public License (GPLv3). You are bound by the terms of the license. You may find #
# a copy of the license included in this repository or you may find a copy of the #
# license at <http://www.gnu.org/licenses/>.                                      #
###################################################################################

# Check if the user is running as root.
if [[ $EUID -ne 0 ]]; then
	echo "Failing. This script must be run as 'root'. Please try again."
	exit 1
fi

selinux_reboot_flag="0" # This flag is only activated if the script had to update SELinux to use enforcing mode.


############# DISTROS #############
fedora()
{
	# Checks if the user is running Fedora 19.
	releasenum=`cat /etc/fedora-release | awk {'print $3'}`
	if [ $releasenum == "19" ]; then
		:
	else
		echo "ERROR: Fedora" $releasenum "is not currently supported."
		exit 1
	fi
	# Update the OS:
	yum -y update

	# Install dependencies:
	yum -y install unzip augeas httpd-tools puppet bind ruby

	# Fix SELinux settings so they are enforcing instead of disabled.

	path_to_selinux="/etc/selinux/config"

	if grep -q "enforcing" $path_to_selinux; then
		: # NOP
	else
		echo > $path_to_selinux  # Clear the file.
		echo -e "SELINUX=enforcing\nSELINUXTYPE=targeted" > $path_to_selinux # Enable enforcing.
		selinux_reboot_flag="1" # Make sure the system reboots.
	fi

	# Change the user's hostname.
	echo $user_hostname > /etc/hostname
	hostname $user_hostname

	echo "Successfully prepped your Fedora system."
}
centos()
{
	# Check version of CentOS.
	releasenum=`cat /etc/*-release* | awk {'print $3'}`
	# Add OpenShift repos.
	touch /etc/yum.repos.d/openshift-origin-deps.repo
	touch /etc/yum.repos.d/openshift-origin.repo
	echo -e "[openshift-origin-dep]\nname=openshift-origin-deps\nbaseurl=http://mirror.openshift.com/pub/origin-server/release/3/rhel-6/dependencies/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/openshift-origin-deps.repo
	echo -e "[openshift-origin]\nname=openshift-origin\nbaseurl=http://mirror.openshift.com/pub/origin-server/release/3/rhel-6/packages/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/openshift-origin.repo

	# Add EPEL repos.
	sudo yum -y install http://mirror.metrocast.net/fedora/epel/6/i386/epel-release-6-8.noarch.rpm


	# Update the OS:
	yum -y update

	# Install dependencies:
	yum -y install ruby ruby193 unzip curl scl-utils httpd-tools puppet bind bind-utils augeas

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
	# Check the version of RHEL.
	rh_releasenum=`cat /etc/redhat-release | awk {'print $7'}`

	if [[ $rh_releasenum == *"6.5"* ]]; then
		echo "Installing on RHEL 6.5"
		yum -y install http://mirror.metrocast.net/fedora/epel/6/i386/epel-release-6-8.noarch.rpm
		yum -y update
		yum -y install ruby193 ruby puppet augeas bind httpd-tools curl


		# For some hosts, we need to make sure SELinux is properly configured.
		if [ `getenforce` == "Enforcing"]; then
			echo "SELinux is properly configured."
			:
		else
			echo > /etc/selinux/config # Clear the config file.
			echo -e "SELINUX=enforcing\nSELINUXTYPE=targeted" > /etc/selinux/config # Enable enforcing.
		fi

		# Update the hostname.
		echo $user_hostname > /etc/hostname
		hostname $user_hostname
	elif [[ $releasenum == *"7"* ]]; then
		echo "Installing on RHEL 7"
		echo "Failing: RHEL 7 is currently not supported."
		exit 1
	else
		echo "Error: I cannot install on RHEL " $rh_releasenum ", please try the installation on RHEL 6.5." 
	fi
}

distro()
{
	# Check the distro that the user is running.
	distroname=`cat /etc/*-release | awk 'NR==1{print $1}'`

	if [ -f "/etc/redhat-release" ]; then
		if [[ `cat /etc/redhat-release | awk 'NR==1{print $1 " " $2}'` == "Red Hat" ]]; then
			echo "Looks like you're running Red Hat."
			redhat
		elif [[ `cat /etc/redhat-release | awk 'NR==1{print $1}'` == "CentOS" ]]; then
			echo "Looks like you're running CentOS"
			centos
		elif [[ $distroname == *"Fedora"* ]]; then
			fedora
		fi
	else
		echo ""
		echo "Unsupported Linux distribution. Please use Red Hat Enterprise Linux, CentOS, or Fedora."
		exit 1
	fi
}
######### Stage 1 ############
preflight()
{
	# Installs the necessary dependencies to get OpenShift running.
	touch .LOCK_SLE # Create a lock.
	distro
	if [ $selinux_reboot_flag == "1" ]; then
		reboot # Only if the SELinux config file needed to be updated.
		exit 1
	elif [ $selinux_reboot_flag == "0" ]; then
		installer_menu # Typical case.
	fi
	# Make sure this script doesn't go through 
}

######### Stage 2 ###########
origin_install()
{
	# If the user chooses Origin, then run the Origin installer.
	echo "PHASE 2: Now installing OpenShift Origin. "
	sh <(curl -s https://install.openshift.com/)

	rm -Rf .LOCK_SLE
	echo "Script is finished."
	reboot
	exit 0
}

enterprise_install()
{
	# If user chooses Enterprise, then run the Enterprise installer.
	sh <(curl -s https://install.openshift.com/ose) -e
	rm -Rf .LOCK_SLE
	echo "Finishing."
	reboot
	exit 0
}

installer_menu()
{
	# Lets the user choose which version they want to install.
	clear
	echo "Welcome back to the OpenShift Quick Installer. Before continuing, you will need to tell me whether you're installing Origin or Enterprise."
	echo -e ""
	PS3='Please enter the # for your choice: '
	options=("Install Origin" "Install Enterprise" "Quit")
	select opt in "${options[@]}"

	do
		case "$REPLY" in
			1)
				echo "Installing Origin."
				origin_install
				;;
			2)
				echo "Installing Enterprise"
				enterprise_install
				;;
			3)
				echo "Quitting."
				rm -Rf .LOCK_SLE
				break;;
			*)
			 echo "Invalid selection."
	 	esac
	 done


}

# Get the desired hostname from the user.
hostname_input()
{
	echo -e -n "\nPlease enter the hostname that you wish to use.  "
	read  user_hostname
	echo -e -n "You chose" $user_hostname "is that correct? [y/n] "
	read  hostname_bool

	if [ $hostname_bool == "y" ]; then
		preflight
	elif [ $hostname_bool == "n" ]; then
		hostname_input
	else
		hostname_input
	fi
}




#### Main Routine #####

# First run
clear
if [ ! -f ".LOCK_SLE" ]; then
	printf "Welcome to the OpenShift Quick Installer. You will be asked a series of questions during this installation. "
	printf "For best results, we highly recommend you install this on a fresh install of Red Hat Enterprise Linux or CentOS. "
	printf "\n\nDuring the installation process, your computer may restart. You will need to rerun this script (by typing './install.sh' as root, "
	printf "once your computer restarts. Ready to begin?\n\n"
	read -p "Press enter to continue..."

	hostname_input
fi

# Second run
if [ -f ".LOCK_SLE" ]; then
	installer_menu
fi
