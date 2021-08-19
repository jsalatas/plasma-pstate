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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

RowLayout {
    Layout.fillWidth: true

    property var sensor: []
    
    property bool acceptingChanges: false
    property alias text: combobox_title.text
    property var props
    spacing: 10

    onPropsChanged: {
        acceptingChanges = false

        var filtered = props['items']
        if (props['sensor'] in available_values) {
            var values = available_values[props['sensor']]
            filtered = filtered.filter(item => {
                return values.includes(item['sensor_value'])
            })
        }

        combobox.model = filtered
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
                var value = sensors_model[sensor[0]]['value'];
                for(var i = 0; i < combobox.model.length; i++) {
                    if(combobox.model[i].sensor_value == value) {
                        combobox.currentIndex = i
                    }
                }
            }
            acceptingChanges = true
        }
    }
    
    Label {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        id: combobox_title
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        Layout.minimumWidth: units.gridUnit * 4
    }

    ComboBox {
        id: combobox
        textRole: "text"

        property bool customHovered: false

        onActivated: {
            if(acceptingChanges) {
                updateSensor(sensor[0], combobox.model[currentIndex].sensor_value)
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                combobox.customHovered = true
            }
            onExited: {
                combobox.customHovered = false
            }
            onClicked: {
                combobox.down ?
                    combobox.popup.close() :
                    combobox.popup.open()
            }
        }

        delegate: ItemDelegate {
            id: itemDelegate
            width: combobox.width
            contentItem: Text {
                text: modelData.text
                color: theme.textColor
                font: combobox.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
            highlighted: combobox.highlightedIndex == index
            background: Rectangle {
                color: theme.backgroundColor
                border.color: Qt.rgba(0, 0, 0, 0)
                radius: 0
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    contentItem.color = theme.highlightColor
                }
                onExited: {
                    contentItem.color = theme.textColor
                }
                onClicked: {
                    combobox.currentIndex = index
                    combobox.popup.close()
                    combobox.onActivated(index)
                }
            }
        }

        indicator: Canvas {
            id: canvas
            x: combobox.width - width - combobox.rightPadding
            y: combobox.topPadding + (combobox.availableHeight - height) / 2
            width: units.gridUnit * 0.5
            height: width * 0.75
            contextType: "2d"

            Connections {
                target: combobox
                function onDownChanged() { canvas.requestPaint(); }
                function onCustomHoveredChanged() { canvas.requestPaint(); }
            }

            onPaint: {
                var ctx = context
                if (!context) {
                    ctx = getContext ("2d");
                }
                ctx.reset();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width / 2, height);
                ctx.closePath();
                ctx.fillStyle = combobox.down || combobox.customHovered ?
                                        theme.highlightColor : theme.textColor;
                ctx.fill();
            }
        }

        contentItem: RowLayout {
            Text {
                Layout.leftMargin: 0
                Layout.rightMargin: combobox.indicator.width * 2
                Layout.alignment: Qt.AlignRight

                text: combobox.displayText
                font: combobox.font
                color: combobox.pressed ? theme.textColor : theme.highlightColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
        }

        background: Rectangle {
            color: Qt.rgba(0, 0, 0, 0)
            border.color: theme.highlightColor
            border.width: combobox.down || combobox.customHovered ? 1 : 0
            radius: 2
        }
    }
}
