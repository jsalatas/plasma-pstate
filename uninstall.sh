#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 2>&1
    exit 1
fi

kpackagetool5 -g -t Plasma/Applet -r org.thefreecircle.mibofra.plasma.pstate

rm /usr/share/polkit-1/actions/org.thefreecircle.mibofra.plasma.pstate.get-thermal.policy
rm /usr/share/polkit-1/actions/org.thefreecircle.mibofra.plasma.pstate.set-prefs.policy

echo "Uninstall complete."
exit 0
