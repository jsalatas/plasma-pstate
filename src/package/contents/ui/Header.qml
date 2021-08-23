/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

import "./" as Pstate
import '../code/utils.js' as Utils

RowLayout {
    id: header

    Layout.topMargin: 5
    Layout.bottomMargin: 5

    property alias symbol: icon.text
    property alias text: title.text
    property var sensors: []
    property var items: []

    property var props
    property var showIcon: true

    Layout.alignment: Qt.AlignTop | Qt.AlignLeft

    Component {
        id: group
        Pstate.Group {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }
    }

    Component {
        id: radio
        Pstate.Radio {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }
    }
    
    Component {
        id: switchbutton
        Pstate.Switch {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }
    }

    Component {
        id: combobox
        Pstate.ComboBox {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }
    }

    Connections {
        target: main
        onSensorsValuesChanged: {
            sensors_label.text = get_sensors_text(sensors);
        }
    }

    onItemsChanged: {
        // parent: controls
        for(var i = 0; i < items.length; i++) {
            if(!Utils.sensor_has_value(items[i])) {
                continue
            }

            switch (items[i]['type']) {
                case 'radio': {
                    radio.createObject(controls, {'props': items[i]})
                    break
                }
                case 'group': {
                    group.createObject(controls, {'props': items[i]})
                    break
                }
                case 'switch': {
                    switchbutton.createObject(controls, {'props': items[i]})
                    break
                }
                case 'combobox': {
                    combobox.createObject(controls, {'props': items[i]})
                    break
                }
                default: console.log("header: unkonwn type: " + items[i]['type'])
            }
        }
    }

    onPropsChanged: {
        symbol = props['icon']
        text = props['text']
        sensors = props['sensors']
        items = props['items']
    }

    GridLayout {
        id: grid

        columns: header.showIcon ? 2 : 1
        columnSpacing: 10
        rowSpacing: 0

        Layout.alignment: Qt.AlignTop | Qt.AlignLeft

        Label {
            id: icon

            width: units.gridUnit * 2.2
            Layout.minimumWidth : width

            horizontalAlignment: Text.AlignHCenter

            font.pointSize: theme.defaultFont.pointSize * 1.5
            font.family: symbolsFont.name
            color: theme.textColor

            visible: header.showIcon
        }

        Label {
            id: title

            font.pointSize: theme.defaultFont.pointSize * 1.25
            color: theme.textColor
        }

        Label  {
            id: spacer0
            visible: sensors_label.text != 'N/A' && header.showIcon
        }

        Label {
            id: sensors_label
            text: get_sensors_text(sensors)

            Layout.bottomMargin: 5

            font.pointSize: theme.smallestFont.pointSize
            color: Qt.rgba(theme.textColor.r,
                           theme.textColor.g,
                           theme.textColor.b, 0.6)

            visible: sensors_label.text != 'N/A'
        }

        Label  {
            id: spacer1
            visible: header.showIcon
        }

        ColumnLayout {
            id: controls
        }
    }
}
