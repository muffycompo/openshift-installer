openshift-installer
===================
Welcome to the OpenShift Easy Install Script. This script takes the hassle out of installing OpenShift by handling the preconfiguration and dependency installation for you. To run this script, all you need to do is enter the following into your shell prompt:

```curl https://raw.githubusercontent.com/rjleaf/openshift-installer/master/install.sh > install.sh && chmod +x install.sh && sudo ./install.sh```

Once you run that command, you will be asked for some information about your server (currently just your desired hostname). Then, we'll take care of configuring your server. If you didn't have SELinux enabled prior to running this script, then this script will make the necessary changes and reboot your machine.

If your system restarts, you will need to rerun the install script by typing the following:

```su root``` [If not root already]

```./install.sh```

From there, you should be able to smoothly sail through the normal OpenShift installation process. At the end of using this script, you should have a fully functional OpenShift broker or node.

## Compatibility ##
This script has been tested to work with the following distros:
  - Fedora 19 x64
  - Red Hat Enterprise Linux 6.5
  - CentOS 6.5

[Note: I've tested this on a DigitalOcean droplet. DigitalOcean includes images with SELinux available, but not enabled. This script enables SELinux on your behalf. Some VPS providers may not include SELinux - unfortunately this script does not yet provide the capability to install and configure SELinux for you.]


## Proposed Features ##
These are features that are currently under development and have not yet been implemented.
  - Support for Red Hat Enterprise Linux 7. Support will be added once issues with Puppet on RHEL7 are resolved.   
  
## Authors ##
We hope you benefit from the install script. If you have any questions, feel free to contact one of our authors:

- Ryan Leaf - ryan [*at*] ryanleaf [*dot*] org
