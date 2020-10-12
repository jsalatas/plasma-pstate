#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi

POLKIT_FILE="org.pkexec.set_prefs.policy"
POLKIT_PATH="/usr/share/polkit-1/actions"
SYSTEMD_FILE='set_prefsd'
UNITDIR_PATH='/usr/lib/systemd/system'

cp -f ${POLKIT_FILE} ${POLKIT_PATH} 
cp -f ${SYSTED_FILE} ${UNITDIR_PATH} 

systemctl daemon-reaload 
systemctl enable set_perfsd
systemctl start set_perfsd

kpackagetool5 -g -t Plasma/Applet -i gr.ictpro.jsalatas.plasma.pstate

chmod 755 /usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh

echo -e "\nSetup complete."
exit 0
