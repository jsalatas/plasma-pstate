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
    property var items: []

    property var props
    property bool showIcon: true

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

    function createItem(sensorItem) {
        switch (sensorItem['type']) {
            case 'radio': {
                radio.createObject(controls, {'props': sensorItem})
                break
            }
            case 'group': {
                group.createObject(controls, {'props': sensorItem})
                break
            }
            case 'switch': {
                switchbutton.createObject(controls, {'props': sensorItem})
                break
            }
            case 'combobox': {
                combobox.createObject(controls, {'props': sensorItem})
                break
            }
            default: console.log("header: unkonwn type: " + sensorItem['type'])
        }
    }

    function createEnumerableSensor(sensorModel, sensorItem) {
        var enumRootName = sensorModel.sensor
        var enumSensors = sensorModel.value

        for (var j = 0; enumSensors && j < enumSensors.length; j++) {
            var item = Utils.deepCopy(sensorItem)
            item['sensor'] = enumRootName + "/" + enumSensors[j]
            item['text'] = item['text'] + " / " + enumSensors[j]
            item['value'] = ""
            createItem(item)
        }
    }

    onItemsChanged: {
        // parent: controls
        for(var i = 0; i < items.length; i++) {
            if(!Utils.sensor_has_value(items[i])) {
                continue
            }

            var sensorItem = items[i]

            var sensorName = sensorItem['sensor']
            var sensorModel = main.sensorsMgr.getSensor(sensorName)

            if (Utils.is_enum_sensor(sensorModel)) {
                createEnumerableSensor(sensorModel, sensorItem)
            } else {
                createItem(sensorItem)
            }
        }
    }

    onPropsChanged: {
        symbol = props['icon']
        text = props['text']
        items = props['items']

        var keys = props['sensors']
        var prevLabel = undefined
        for (var i = 0; keys && i < keys.length ; i++) {
            var sensorModel = main.sensorsMgr.getSensor(keys[i])
            var p = { "sensorModel": sensorModel, "prevLabel": prevLabel }
            var label = sensorLabelComp.createObject(sensorLabels, p)
            prevLabel = label

            sensorModel.emitValueChanged()
        }
    }

    Component {
        id: sensorLabelComp

        Label {
            property string valueText: ""
            property var sensorModel: undefined
            property var prevLabel: undefined

            Layout.bottomMargin: 5
            Layout.rightMargin: 0

            text: ""
            font.pointSize: theme.smallestFont.pointSize
            color: Qt.rgba(theme.textColor.r,
                           theme.textColor.g,
                           theme.textColor.b, 0.6)

            visible: valueText !== "N/A"

            onSensorModelChanged: {
                sensorModel.onValueChanged.connect(onValueChanged)
            }

            function onValueChanged() {
                valueText = sensorModel.getValueText()
                if (!valueText || valueText === "") {
                    valueText = "N/A"
                }

                var spacer = ""
                if (prevLabel && prevLabel.visible) {
                    spacer = "| "
                }

                text = spacer + valueText
            }

            Component.onDestruction: {
                sensorModel.onValueChanged.disconnect(onValueChanged)
            }
        }
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
            visible: header.showIcon
        }


        RowLayout {
            id: sensorLabels
            Layout.fillWidth: false
            Layout.fillHeight: false
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
