/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2

RowLayout {
    property alias text: checkbox_title.text
    property alias checked: checkBox.checked
    property var sensor: []
    property bool acceptingChanges: false

    property var props
    spacing: 10

    onPropsChanged: {
        acceptingChanges = false

        text = props['text']
        sensor.push(props['sensor'])
        acceptingChanges = true
    }

    Component.onCompleted: {
        acceptingChanges = true
        sensorsValuesChanged()
    }

    Connections {
        target: main
        onSensorsValuesChanged: {
            acceptingChanges = false

            if(sensor.length != 0) {
                checked = sensors_model[sensor[0]]['value'] == 'true';
            }

            acceptingChanges = true
        }
    }

    Label {
        Layout.alignment: Qt.AlignVCenter
        id: checkbox_title
        font.pointSize: theme.smallestFont.pointSize
        color: theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: units.gridUnit * 4
    }

    CheckBox {
        id: checkBox
        onCheckedChanged: {
            if(acceptingChanges) {
                updateSensor(sensor[0], checked)
            }
        }
    }
}
