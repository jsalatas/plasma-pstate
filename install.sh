#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi

kpackagetool5 -g -t Plasma/Applet -i org.thefreecircle.mibofra.plasma.pstate

chmod 755 /usr/share/plasma/plasmoids/org.thefreecircle.mibofra.plasma.pstate/contents/code/set_prefs.sh
chmod 755 /usr/share/plasma/plasmoids/org.thefreecircle.mibofra.plasma.pstate/contents/code/get_thermal.sh

cp org.thefreecircle.mibofra.plasma.pstate/contents/code/org.thefreecircle.mibofra.plasma.pstate.get-thermal.policy /usr/share/polkit-1/actions/ 
cp org.thefreecircle.mibofra.plasma.pstate/contents/code/org.thefreecircle.mibofra.plasma.pstate.set-prefs.policy /usr/share/polkit-1/actions/

echo -e "\nSetup complete."
exit 0
