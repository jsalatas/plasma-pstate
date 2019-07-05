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

import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.components 2.0 as PlasmaComponents

Row {
    id: header

    topPadding: 5
    bottomPadding: 10

    property alias symbol: icon.text
    property alias text: title.text
    property var sensors: []
    property var items: []

    property var props

    Component {
        id: group
        Group {
            Layout.topMargin: 5
            Layout.bottomMargin: 10
        }
    }

    Component {
        id: radio
        Radio {
            Layout.topMargin: 5
            Layout.bottomMargin: 10
        }
    }
    
    Component {
        id: switchbutton
        Switch {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }
    }

    Component {
        id: combobox
        ComboBox {
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

        columns: 2
        columnSpacing: 10
        rowSpacing: 0

        PlasmaComponents.Label {
            id: icon

            width: units.gridUnit * 2.2
            Layout.minimumWidth : width

            horizontalAlignment: Text.AlignHCenter

            font.pointSize: theme.smallestFont.pointSize * 2.5
            font.family: symbolsFont.name
            color: theme.textColor
        }

        PlasmaComponents.Label {
            id: title

            font.pointSize: theme.smallestFont.pointSize * 2
            color: theme.textColor
        }

        PlasmaComponents.Label  {
            id: spacer0
            visible: sensors_label.text != 'N/A'
        }

        PlasmaComponents.Label {
            id: sensors_label

            Layout.bottomMargin: 5

            font.pointSize: theme.smallestFont.pointSize * 1.25
            color: theme.textColor
            opacity: 0.8

            visible: sensors_label.text != 'N/A'
        }

        PlasmaComponents.Label  {
            id: spacer1
        }

        ColumnLayout {
            id: controls
        }
    }
}
