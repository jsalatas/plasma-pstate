/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.0


Item {
    id: firstInit

    readonly property bool debug: false

    // Stage One
    property bool isScriptReady: false
    property bool isMonitorReady: false

    // Stage Two
    property bool isViewReady: false
    property bool isDataReady: false

    signal beginStageOne
    signal beginStageTwo
    signal initialized

    function scriptReady() {
        isScriptReady = true;
        checkStageOne()
    }

    function monitorReady() {
        isMonitorReady = true;
        checkStageOne()
    }

    function checkStageOne() {
        printdbg("init: stage one: isScriptReady = " + isScriptReady +
                 ", isMonitorReady = " + isMonitorReady)

        if (isScriptReady === true && isMonitorReady === true) {
            printdbg("init: stage one: Done.")

            printdbg("init: stage two: Can begin.")
            /* emit */ beginStageTwo()
        }
    }

    function viewReady() {
        isViewReady = true
        checkStageTwo()
    }

    function dataReady() {
        isDataReady = true
        checkStageTwo()
    }

    function checkStageTwo() {
        printdbg("init: stage two: isViewReady = " + isViewReady +
                 ", isDataReady = " + isDataReady)
        if (isViewReady == true && isDataReady === true) {
            printdbg("init: stage two: Done.");
            printdbg("init: emit initialized()")
            /* emit */ initialized()
        }
    }

    function printdbg(args) {
        if (this.debug === true) {
            print(args)
        }
    }
}
