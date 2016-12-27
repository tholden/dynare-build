#!/bin/bash

PACKAGES=$(cat libs/requirements.txt)
PACKAGES="$PACKAGES $(cat requirements.txt)"

if [ $EUID -ne 0  ]; then
    sudo apt-get install $PACKAGES
    sudo apt-get autoremove
    sudo apt-get clean
else
    apt-get install $PACKAGES
    apt-get autoremove
    apt-get clean
fi
