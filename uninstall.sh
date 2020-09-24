#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi


POLKIT_FILE="org.pkexec.set_prefs.policy"
POLKIT_PATH="/usr/share/polkit-1/actions"
rm -f ${POLKIT_PATH}/${POLKIT_FILE}
kpackagetool5 -g -t Plasma/Applet -r gr.ictpro.jsalatas.plasma.pstate

echo "Uninstall complete."
exit 0
