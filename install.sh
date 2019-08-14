#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi

SUDOERS_FILE="99-plasma-pstate"

cp -R ${SUDOERS_FILE} /etc/sudoers.d/
kpackagetool5 -g -t Plasma/Applet -i gr.ictpro.jsalatas.plasma.pstate

chmod 755 /usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh

chown root:root /etc/sudoers.d/${SUDOERS_FILE}
chmod 400 /etc/sudoers.d/${SUDOERS_FILE}

# Test for wheel group instead of sudo
# this is the case of arch based distros
wheelgroup=`grep wheel /etc/group | wc -l`
sudogroup=`grep sudo /etc/group | wc -l`
if [ "$wheelgroup" -eq "1" ] && [ "$sudogroup" -eq "0" ]; then
    # seems to be safe enough: there is a wheel group and not a sudo group
    sed -i 's/sudo/wheel/' /etc/sudoers.d/${SUDOERS_FILE}
fi

echo -e "\nSetup complete."
exit 0
