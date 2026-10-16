#!/bin/bash
cd "$(dirname "$0")"
export PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC
make image 2>&1
