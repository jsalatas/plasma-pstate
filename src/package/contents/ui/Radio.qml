/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

ColumnLayout {
    id: radio

    property alias text: radio_title.text
    property var sensor: []
    property var items: []

    property var props

    objectName: "Radio"

    Component {
        id: pushButton
        PushButton {}
    }

    onPropsChanged: {
        text = props['text']
        sensor.push(props['sensor'])
        items = props['items']
    }

    onItemsChanged: {
        for(var i = 0; i < items.length; i++) {
            var props = items[i]
            props['sensor'] = sensor
            pushButton.createObject(buttons, props);
        }
    }

    Label {
        id: radio_title
        font.pointSize: theme.smallestFont.pointSize * 1.25
        color: theme.textColor
        visible: text != ''
        Layout.fillWidth: true
    }
    RowLayout {
        id: buttons
        spacing: -0.5
        Layout.topMargin: radio_title.visible ? 0 : 8
        // Layout.rightMargin: 15

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true

        height: units.gridUnit * 4
    }
}
