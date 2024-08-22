#!/bin/sh

# set -eoux pipefail

if [ -z "${USER+x}" ]; then
  echo "User is not set, setting it to $NB_USER"
  USER=$NB_USER
else
  echo "setting NB_USER=$USER"
  export NB_USER=$USER
fi 

export USER=${USER-"cloudbeaver"}
export DEFAULT_USER="cloudbeaver"
export HOME="/home/$USER"
export NB_ROOT_DIR=${NB_ROOT_DIR-$HOME}
export WORKDIR=/opt/cloudbeaver

# Add other init scripts in $HELX_SCRIPTS_DIR with ".sh" as their extension.
# To run in a certain order, name them appropraitely. 
HELX_SCRIPTS_DIR=/helx/helx-init-scripts
INIT_SCRIPTS_TO_RUN=$(ls -1 $HELX_SCRIPTS_DIR/*.sh) || true
for INIT_SCRIPT in $INIT_SCRIPTS_TO_RUN
do
  echo "Running $INIT_SCRIPT"
  $INIT_SCRIPT
done
# Run the cloudbeaver app after HeLx is setup
chmod +x $WORDKIR/run-server.sh
cd $WORKDIR
./run-server.sh
