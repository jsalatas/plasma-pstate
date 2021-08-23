/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.2
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Controls 2.2

Item {
    PlasmaCore.IconItem {
        id: customIcon
        anchors.fill: parent
        visible: !plasmoid.configuration.useDefaultIcon
        source: plasmoid.configuration.customIcon
    }


    Label {
        anchors.fill: parent
        visible: plasmoid.configuration.useDefaultIcon

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        font.pixelSize: Math.min(parent.height, parent.width) * (inTray ? 1: 0.7)
        font.pointSize: -1
        font.family: symbolsFont.name

        text: 'd'
    }
    
    MouseArea {
        id: mousearea
        anchors.fill: parent
        onClicked: {
            plasmoid.expanded = !plasmoid.expanded
        }
    }
}
