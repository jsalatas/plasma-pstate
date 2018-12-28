/*
 *   Copyright 2018 John Salatas <jsalatas@ictpro.gr>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    width: units.gridUnit * 4
    height: units.gridUnit * 4

    objectName: "PushButton"

    property string symbol
    property alias text: label.text
    property string sensor_value
    property bool active: false
    property bool updating: false
    property var sensor: []
    property bool acceptingChanges: false

    property color borderColor: updating ? '#ff0000' : (active ? Qt.rgba(theme.highlightColor.r, theme.highlightColor.g, theme.highlightColor.b, 0.6) : 
                                         Qt.rgba(theme.textColor.r,      theme.textColor.g,      theme.textColor.b,      0.4))
    property color buttonColor: active ? theme.highlightColor : theme.textColor
    
    Connections {
        target: main
        onSensorsValuesChanged: {
            acceptingChanges = false
            updating = false
            active = sensors_model[sensor[0]]['value'] == sensor_value
            acceptingChanges = true
        }
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
                    updateSensor(sensor[0], sensor_value)
                }
            }
        }
        
        PlasmaComponents.Label {
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
        
        PlasmaComponents.Label {
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
