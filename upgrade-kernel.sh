#!/usr/bin/env bash

##
# This script will download a kernel, compile it using the same settings as 
# your current kernel, and add it to grub2 or grub if possible.
# TODO: add automated patching prior to compilation
##

KERNEL_VERSION=3.9.11
KERNEL_SRC_DIR=/usr/local/src

set -e

mkdir -p $KERNEL_SRC_DIR
cd $KERNEL_SRC_DIR

if [[ ! -e linux-$KERNEL_VERSION.tar.gz && ! -e linux-$KERNEL_VERSION ]]; then
    wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-$KERNEL_VERSION.tar.gz
fi

if [ ! -e linux-$KERNEL_VERSION ]; then
    tar xvzf linux-$KERNEL_VERSION.tar.gz
fi

if [ -e linux-$KERNEL_VERSION ]; then
    echo "kernel source is in $KERNEL_SRC_DIR/linux-$KERNEL_VERSION, starting build process..."
    cd linux-$KERNEL_VERSION
    # use our existing config, this may not be the most optimal thing
    # editing here is recommended
    cp /boot/config-`uname -r` .config
    # make oldconfig will prompt us for any options not set in our
    # existing config file
    make oldconfig
    # j<num_of_processes> two seems like a nice default
    make -j2
    # Now that the kernel is built we can take advantage of existing
    # helper scripts to handle installing drivers, settings up ramdisk,
    # and adding the image to /boot
    make modules_install install
    # Make boot loader aware of the new version so it shows in the boot menu
    update-grub2 || update-grub || update-burg
    echo "Kernel $KERNEL_VERSION has been installed."
    exit 0
else
    echo "failed to fetch kernel source"
    exit 1
fi
