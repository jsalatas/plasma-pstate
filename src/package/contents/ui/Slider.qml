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


    property var sensor: []
    property var min_sensor: []
    property var max_sensor: []


    property alias text: slider_title.text
    property var props
    spacing: 10

    onPropsChanged: {
        acceptingChanges = false
        text = props['text']
        sensor.push(props['sensor'])
        if(isNaN(props['min'])) {
            min = 0
            min_sensor.push(props['min'])
        } else {
            min = props['min']
            min_sensor = []
        }
        if(isNaN(props['max'])) {
            max = 100
            max_sensor.push(props['max'])
        } else {
            max = props['max']
            max_sensor = []
        }
        acceptingChanges = true
    }

    Component.onCompleted: {
        acceptingChanges = true
        sensorsValuesChanged()
    }

    Connections {
        target: main
        onSensorsValuesChanged: {
            if(!pressed) {
                acceptingChanges = false
                if(sensor.length != 0) {
                    value = parseInt(sensors_model[sensor[0]]['value'], 10);
                    slider_value.text = get_sensors_text(sensor);
                    updating = false
                }
                if(min_sensor.length != 0) {
                    min = parseInt(sensors_model[min_sensor[0]]['value'], 10);
                }
                if(max_sensor.length != 0) {
                    max = parseInt(sensors_model[max_sensor[0]]['value'], 10);
                }
                acceptingChanges = true
            }
        }
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
                updateSensor(sensor[0], Math.round(value))
            }
        }
        onValueChanged: {
            if(pressed) {
                updating = true
                slider_value.text = get_value_text(sensor[0], value)
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
