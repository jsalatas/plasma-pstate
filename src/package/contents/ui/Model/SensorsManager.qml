/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.0

import '../../code/utils.js' as Utils


QtObject {
    objectName: "SensorsManager"
    id: sensorsMgr

    property var sensorsMap: ({})

    property var availableValues: ({})

    property var detectedSensors: []

    property var sensorComponent

    function loadSensors() {
        var sensors_model = Utils.get_sensors()

        sensorComponent = Qt.createComponent("./Sensor.qml");
        if (sensorComponent.status !== Component.Ready) {
            print("Sensor.qml component not ready.")
            return
        }

        var keys = Object.keys(sensors_model)
        for (var i = 0; i < keys.length; i++) {
            var obj = sensors_model[keys[i]]

            var sensor = sensorComponent.createObject(sensorsMgr, {
                "sensor": keys[i],
                "value": sensors_model[keys[i]]["value"],
                "unit": sensors_model[keys[i]]["unit"],
                "print_func": sensors_model[keys[i]]["print"],
                "rw_mode": sensors_model[keys[i]]["rw_mode"],
                "sensor_type": sensors_model[keys[i]]["sensor_type"],
            })

            sensorsMap[keys[i]] = sensor
        }
    }

    function getKeys() {
        return Object.keys(sensorsMap)
    }

    function hasKey(name) {
        return name in sensorsMap
    }

    function getSensor(name) {
        if (name in sensorsMap) {
            return sensorsMap[name]
        }
        return undefined
    }

    function setSensorValue(name, value) {
        var sensor = getSensor(name)
        if (sensor) {
            sensor.value = value
            return true
        }
        return false
    }

    /*
     * returns { sensor1: value, sensor2: value, ... }
     */
    function backupSensorValues() {
        var backup = {}
        var keys = Object.keys(sensorsMap)
        for (var i = 0; i < keys.length; i++) {
            backup[keys[i]] = sensorsMap[keys[i]].value
        }
        return backup
    }

    function restoreSensorValues(backup) {
        var keys = Object.keys(backup)
        for (var i = 0; i < keys.length; i++) {
            sensorsMap[keys[i]].value = backup[keys[i]]
        }
    }

    function initEnumerableSensor(sensorModel) {
        var enumSensors = sensorModel.value

        for (var j = 0; enumSensors && j < enumSensors.length; j++) {
            var enumSensorName = sensorModel.sensor + "/" + enumSensors[j]
            var enumSensor = sensorComponent.createObject(sensorsMgr)
            enumSensor = enumSensor.copy(sensorModel)
            enumSensor.sensor = enumSensorName
            enumSensor.sensor_type = ""

            sensorsMap[enumSensorName] = enumSensor
            detectedSensors.push(enumSensorName)
        }
    }

    function initSensorsDetected() {
        detectedSensors = []
        var keys = getKeys()
        for (var i = 0; i < keys.length; i++) {
            var sensorModel = getSensor(keys[i])

            if (detectedSensors.includes(sensorModel.name)) {
                continue
            }
            if (sensorModel.value === undefined) {
                continue
            }
            if (Utils.is_sysmon_sensor(sensorModel))
            {
                continue
            }
            if (Utils.is_enum_sensor(sensorModel))
            {
                initEnumerableSensor(sensorModel)
            }
            detectedSensors.push(keys[i])
        }
    }
}
