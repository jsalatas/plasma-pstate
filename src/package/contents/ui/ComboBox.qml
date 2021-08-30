/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

RowLayout {
    Layout.fillWidth: true

    property var sensorModel: undefined
    
    property bool acceptingChanges: false
    property alias text: combobox_title.text
    property var props
    spacing: 0


    function onValueChanged() {
        acceptingChanges = false
        var value = sensorModel.value
        for(var i = 0; i < combobox.model.length; i++) {
            if(combobox.model[i].sensor_value == value) {
                combobox.currentIndex = i
            }
        }
        acceptingChanges = true
    }

    onPropsChanged: {
        acceptingChanges = false

        sensorModel = main.sensorsMgr.getSensor(props['sensor'])

        var filtered = props['items']
        var values = main.sensorsMgr.availableValues[sensorModel.sensor]

        if (filtered && values) {
            // Filter by values in the model view definition
            filtered = filtered.filter(item => {
                return values.includes(item['sensor_value'])
            })
        }

        var values = main.sensorsMgr.availableValues[props['available_values']]
        if (!filtered && values) {
            // Filter by values read from sysfs
            filtered = values.map(val => {
                var text = sensorModel.getValueText(val)
                return { 'text': text, 'sensor_value': val}
            })
        }


        combobox.model = filtered
        text = props['text']
        sensorModel.onValueChanged.connect(onValueChanged)

        acceptingChanges = true
    }

    Component.onCompleted: {
        onValueChanged()
        acceptingChanges = true
    }

    Component.onDestruction: {
        sensorModel.onValueChanged.disconnect(onValueChanged)
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
                updateSensor(sensorModel.sensor,
                             combobox.model[currentIndex].sensor_value)
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
