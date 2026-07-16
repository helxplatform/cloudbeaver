#!/bin/bash

# export CLOUDBEAVER_ROOT_URI="$NB_PREFIX"
# echo "CLOUDBEAVER_ROOT_URI=$CLOUDBEAVER_ROOT_URI/" >> /etc/environment

mkdir -p /opt/cloudbeaver/workspace/.data
cp /helx/cloudconf/.cloudbeaver.runtime.conf /opt/cloudbeaver/workspace/.data/