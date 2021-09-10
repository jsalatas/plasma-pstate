/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Controls 2.2


Item {
    width: units.gridUnit * 3.9
    height: units.gridUnit * 3.8

    objectName: "PushButton"

    property string symbol
    property alias text: label.text
    property string sensor_value
    property bool active: false
    property bool updating: false
    property var sensorModel: undefined
    property bool acceptingChanges: false

    property color borderColor: updating ? '#ff0000' :
                                (active ? Qt.rgba(theme.highlightColor.r,
                                                  theme.highlightColor.g,
                                                  theme.highlightColor.b, 0.6) :
                                          Qt.rgba(theme.textColor.r,
                                                  theme.textColor.g,
                                                  theme.textColor.b, 0.4))
    property color buttonColor: active ? theme.highlightColor : theme.textColor

    function onValueChanged() {
        acceptingChanges = false
        updating = false
        active = sensorModel.value === sensor_value
        acceptingChanges = true
    }

    onSensorModelChanged: {
        sensorModel.onValueChanged.connect(onValueChanged)
        acceptingChanges = true
    }

    Component.onCompleted: {
        onValueChanged()
    }

    Component.onDestruction: {
        sensorModel.onValueChanged.disconnect(onValueChanged)
    }

    Rectangle {
        anchors.fill: parent
        border.width: 2
        border.color: borderColor
        color: "transparent"
        radius: 3
        id: button

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(acceptingChanges) {
                    updating = true
                    updateSensor(sensorModel.sensor, sensor_value)
                }
            }
        }

        Label {
            id: icon
            anchors {
                margins: units.smallSpacing *1.5
                right: parent.right
                left: parent.left
                top: parent.top
            }

            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter

            font.pointSize: theme.smallestFont.pointSize * 2.8
            font.family: symbolsFont.name
            color: buttonColor
 
            text: symbol
        }

        Label {
            id: label
            anchors {
                margins: units.smallSpacing * 1.5
                right: parent.right
                left: parent.left
                bottom: parent.bottom
            }

            verticalAlignment: Text.AlignBottom
            horizontalAlignment: Text.AlignHCenter

            wrapMode: Text.WordWrap
            font.pointSize: theme.smallestFont.pointSize * 0.9
            lineHeight: 0.75

            color: buttonColor
        }
    }
}
