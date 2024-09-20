#!/bin/sh

set -eux pipefail

if [ -z "${USER+x}" ]; then
  echo "USER is not set, setting it to $NB_USER"
  USER=$NB_USER
else
  echo "setting NB_USER=$USER"
  export NB_USER=$USER
fi

export USER=${USER-"cloudbeaver"}
export DEFAULT_USER="cloudbeaver"
export HOME="/home/$USER"
export WORKDIR=/opt/cloudbeaver

cd /

# Add other init scripts in $HELX_SCRIPTS_DIR with ".sh" as their extension.
# To run in a certain order, name them appropraitely. 
HELX_SCRIPTS_DIR=/helx/helx-init-scripts
INIT_SCRIPTS_TO_RUN=$(ls -1 "$HELX_SCRIPTS_DIR"/*.sh 2>/dev/null) || true
for INIT_SCRIPT in $INIT_SCRIPTS_TO_RUN
do
  echo "Running $INIT_SCRIPT"
  chmod +x "$INIT_SCRIPT"
  "$INIT_SCRIPT"
done
# Run the cloudbeaver app after HeLx is setup
cd "$WORKDIR"
chmod +x run-server.sh

./run-server.sh
