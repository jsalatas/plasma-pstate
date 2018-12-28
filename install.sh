#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi

SUDOERS_FILE="99-plasma-pstate"

cp -R ${SUDOERS_FILE} /etc/sudoers.d/
plasmapkg2 -t plasmoid -g -i gr.ictpro.jsalatas.plasma.pstate

chmod 755 /usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh

chown root:root /etc/sudoers.d/${SUDOERS_FILE}
chmod 400 /etc/sudoers.d/${SUDOERS_FILE}

echo -e "\nSetup complete."
exit 0
