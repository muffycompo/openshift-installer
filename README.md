openshift-installer
===================
Welcome to the OpenShift Easy Install Script. This script takes the hassle out of installing OpenShift by handling the preconfiguration and dependency installation for you. To run this script, all you need to do is enter the following into your shell prompt:

```curl https://raw.githubusercontent.com/rjleaf/openshift-installer/master/install.sh && chmod +x install.sh && sudo ./install.sh```

Once you run that command, you will be asked for some information about your server (currently just your desired hostname). Then, we'll take care of configuring your server. At some point, the script will finish and your server will reboot (mainly to get SELinux in the correct state).

You will _need_ to rerun the script to finish the installation. From there, you should be able to smoothly sail through the normal OpenShift installation process. At the end of using this script, you should have a fully functional OpenShift broker or node.

## Compatibility ##
This script has been tested to work with the following distros:
  - Fedora 19 x64

[Note: I've tested this on a DigitalOcean droplet. DigitalOcean includes images with SELinux available, but not enabled. This script enables SELinux on your behalf. Some VPS providers may not include SELinux - unfortunately this script does not yet provide the capability to install and configure SELinux for you.]


## Proposed Features ##
These are features that are currently under development and have not yet been implemented.
  - Support for distributions and hosts that do not include SELinux by default, mainly Debian and Ubuntu.
  - Support for Red Hat Enterprise Linux 7. This shouldn't be an issue since RHEL 7 is very similar to Fedora 19. Once RHEL 7 is released, support will be added.
  - Support for OpenShift Enterprise installations.
   
  
## Authors ##
We hope you benefit from the install script. If you have any questions, feel free to contact one of our authors:

- Ryan Leaf - ryan [*at*] ryanleaf [*dot*] org
