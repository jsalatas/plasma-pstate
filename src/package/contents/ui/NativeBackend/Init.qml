/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.0

//
// Send/receive a test command from the set_prefs.sh script process.
//
Item {
    id: initId

    readonly property var testCmd: ["-list-sensors"]

    /* require */ property bool hasNativeBackend: false

    signal scriptReady

    signal isReadyChanged(bool isReady) /* place holder */
    signal commandFinished() /* place holder */

    function init(scriptReadySignal) {
        scriptReady.connect(scriptReadySignal)
        plasmoid.nativeInterface.startScript();
    }

    Connections {
        target: hasNativeBackend ? plasmoid.nativeInterface : initId
        onCommandFinished: {
            if (data.exitCode === 0 && data.args[0] === testCmd[0]) {
                /* emit */ scriptReady()
            }
        }
        onIsReadyChanged/*(bool isReady)*/: {
            if (hasNativeBackend && isReady) {
                plasmoid.nativeInterface.setPrefs(testCmd)
            }
        }
    }
}
