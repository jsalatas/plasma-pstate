/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.0
import QtQuick.Controls 2.0

Label {
    id: rwModeLabel
    text: "⚠"
    color: "orange"
    visible: sensorModel.rw_mode === "w"

    property var sensorModel: undefined
    property var isHovered: false

    ToolTip {
        text: "Write-only sensor"
        delay: 500
        visible: rwModeLabel.isHovered && rwModeLabel.visible
        parent: rwModeLabel
    }

    MouseArea{
        anchors.fill: parent    
        hoverEnabled: true
        onEntered: rwModeLabel.isHovered = true
        onExited: rwModeLabel.isHovered = false
     }
}
