#!/bin/bash

if [[ -f /.dockerenv ]]
then
    sudo rm -fr $SOURCES_DIR/debian_rfs/rootfs
fi
