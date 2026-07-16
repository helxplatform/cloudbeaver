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
  "$INIT_SCRIPT"
done
# Run the cloudbeaver app after HeLx is setup
cd "$WORKDIR"
# NB_PREFIX has no trailing slash; do NOT add one. A trailing slash makes the
# runtime conf's serviceURI ("${CLOUDBEAVER_ROOT_URI:/api/}/api/") resolve to
# "<prefix>//api/" (double slash), so the GraphQL/WebSocket servlets mount at a
# path that single-slash requests don't match -> 405/404. It also makes Jetty
# warn "contextPath ends with /".
export CLOUDBEAVER_ROOT_URI="$NB_PREFIX"
# Newer CloudBeaver renamed the launcher and added launch-product.sh, which
# (when run as root) su's to the 'dbeaver' user. HeLx runs the container as
# root and chowns /opt/cloudbeaver to 'cloudbeaver', so the su'd 'dbeaver'
# user can't write the OSGi config area -> "Unable to create lock manager".
# Call the inner launcher directly so it runs as root (as the old run-server.sh
# did) and can write its config/workspace.
./run-cloudbeaver-server.sh
