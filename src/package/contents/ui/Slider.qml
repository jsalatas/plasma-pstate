/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

RowLayout {
    property alias min: slider.from
    property alias max: slider.to
    property alias value: slider.value
    property bool acceptingChanges: false
    property alias pressed: slider.pressed
    property bool updating: false


    property alias text: slider_title.text
    property var props
    spacing: 10


    property var sensorModel: undefined
    property var sensorModelMin: undefined
    property var sensorModelMax: undefined


    function onValueChanged() {
        if (pressed) {
            return
        }
        acceptingChanges = false

        value = parseInt(sensorModel.value, 10);
        slider_value.text = sensorModel.getValueText()

        if (sensorModelMin) {
            min = parseInt(sensorModelMin.value, 10);
        }
        if (sensorModelMax) {
            max = parseInt(sensorModelMax.value, 10);
        }

        updating = false
        acceptingChanges = true
    }

    onPropsChanged: {
        text = props['text']

        sensorModel = main.sensorsMgr.getSensor(props['sensor'])
        sensorModel.onValueChanged.connect(onValueChanged)

        if(isNaN(props['min'])) {
            min = 0
            sensorModelMin = main.sensorsMgr.getSensor(props['min'])
        } else {
            min = props['min']
            sensorModelMin = undefined
        }
        if(isNaN(props['max'])) {
            max = 100
            sensorModelMax = main.sensorsMgr.getSensor(props['max'])
        } else {
            max = props['max']
            sensorModelMax = undefined
        }

        onValueChanged()
    }

    Component.onCompleted: {
        onValueChanged()
        acceptingChanges = true
    }

    Component.onDestruction: {
        sensorModel.onValueChanged.disconnect(onValueChanged)
    }

    Label {
        Layout.alignment: Qt.AlignTop
        id: slider_title
        font.pointSize: theme.smallestFont.pointSize
        color: theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: units.gridUnit * 4
    }

    Slider {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignBottom
        id: slider
        stepSize: 0.0
        onPressedChanged: {
            //need to resend here
            if(acceptingChanges) {
                updateSensor(sensorModel.sensor, Math.round(value))
            }
        }
        onValueChanged: {
            if(pressed) {
                updating = true
                slider_value.text = sensorModel.getValueText(value)
            }
        }
    }

    Label {
        Layout.alignment: Qt.AlignTop
        id: slider_value
        font.pointSize: theme.smallestFont.pointSize
        color: pressed || updating? '#ff0000' : theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: units.gridUnit * 3
    }
}
