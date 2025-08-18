#!/bin/bash

# VirtualBox automated repai script - fixer
# Fix error mesage like: "The VirtualBox Linux kernel driver is not loaded or not set up correctly."

#Get VirtualBox version
vbox_version=$((virtualbox --help 2>/dev/null | head -n 1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+") || (vboxmanage --version | grep -oE "[0-9]+\.[0-9]+\.[0-9]+"))

#Updates package list
sudo apt update

#Reinstalls VirtualBox and DKMS (Dynamic Kernel Module Support and automatically rebuilds modules on kernel updates).
sudo apt install --reinstall virtualbox-dkms virtualbox

#Ensures build tools + the kernel headers for your running kernel are installed (needed to compile kernel modules)
sudo apt install build-essential linux-headers-$(uname -r)

#Rebuild the VirtualBox kernel modules
sudo dpkg-reconfigure virtualbox-dkms
sudo dpkg-reconfigure virtualbox

#Load the kernel drivers
sudo modprobe vboxdrv      #Core VirtualBox driver
sudo modprobe vboxnetflt   #Network filter driver (bridged networking).
sudo modprobe vboxnetadp   #Host-only adapter driver

vbox_old_version="6.4.2"
#Checking  version of VirtualBox if it is below 6.4.1 load kerner drive: "vboxpci"
if [[ "$(echo "$vbox_version\n$vbox_old_version" | sort -V | head -n1)" == "$vbox_old_version" ]]; then
    echo -e "\n[*] VirtualBox version $vbox_version(old)\n"
    sudo modprobe vboxpci      #PCI passthrough (removed in newer VirtualBox releases, so this one usually fails)
else
    echo -e "\n[*] VirtualBox version $vbox_version\n"
fi

#Check if modules loaded
lsmod | grep vbox

