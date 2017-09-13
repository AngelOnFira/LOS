#!/bin/bash

# Create a directory structure for the ISO files
rm -rf Build/ISO
mkdir -p Build/ISO
mkdir -p Build/ISO/Boot
mkdir -p Build/ISO/Kernel

# Copy the stage 1 bootloader
cp Build/boot.sys Build/ISO/Boot/boot.sys

# Copy the stage 2 bootloader
cp Build/loader.sys Build/ISO/Boot/loader.sys

# Copy the kernel
#cp Build/los.elf Build/ISO/Boot/los.elf

# Generate the ISO file
genisoimage -R -J -c Boot/bootcat -b Boot/boot.sys -no-emul-boot -boot-load-size 4 -o Build/LOS.iso ./Build/ISO