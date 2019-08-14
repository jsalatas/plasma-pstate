#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi

SUDOERS_FILE="/etc/sudoers.d/99-plasma-pstate"

rm -f ${SUDOERS_FILE}
kpackagetool5 -g -t Plasma/Applet -r gr.ictpro.jsalatas.plasma.pstate

echo "Uninstall complete."
exit 0
