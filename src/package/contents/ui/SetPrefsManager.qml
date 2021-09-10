/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.3

import '../code/utils.js' as Utils
import '../code/datasource.js' as Ds


Item {
    id: manager

    signal setPrefsReady
    signal update(string parameter, var args)


    // The last one to become true emits the signal.
    property bool hasReadSensors: false
    property bool hasReadAvailable: false

    function doFirstInit() {
        if (hasReadSensors && hasReadAvailable) {
            setPrefsReady();
        }
    }

    // Parse the result of "set_prefs.sh -read-all" or "set_prefs.sh -read-some .."
    function handleReadResult(args, stdout) {
        var obj = JSON.parse(stdout);

        var x = args.splice(1)
        Ds.parseSensorData(obj, x)

        if(!hasReadSensors) {
            main.sensorsMgr.initSensorsDetected()
            print("detectedSensors: ", main.sensorsMgr.detectedSensors)

            hasReadSensors = true;
            doFirstInit();
        }
    }

    // Parse the result of "set_prefs.sh -read-available"
    function handleReadAvailResult(stdout) {
        var obj = JSON.parse(stdout);
        var keys = Object.keys(obj);
        var available_values = {}
        for (var i=0; i < keys.length; i++) {
            var d = obj[keys[i]]
            var values = d.split(' ').filter(item => item.length > 0)
            available_values[keys[i]] = values
        }

        main.sensorsMgr.availableValues = available_values

        print("available_values: ", JSON.stringify(available_values))

        hasReadAvailable = true;
        doFirstInit();
    }

    function handleSetValueResult(arg, stdout) {
        var arg_0 = arg
        arg_0 = arg_0.substring(1)
                     .split('-').join('_')
        if (main.sensorsMgr.detectedSensors.includes(arg_0)) {
            var obj = JSON.parse(stdout);

            Ds.parseSensorData(obj, undefined, true)
        }
    }


    function updateSensor(name, value) {
        print("updating sensor " + name +": " + value)

        var sensorModel = main.sensorsMgr.getSensor(name)
        var rw_mode = sensorModel.rw_mode
        var old_val = sensorModel.value

        var args = [value]

        var enumSensors = sensorModel.sensor.split('/')
        if (enumSensors.length > 1) {
            args = enumSensors.slice(1).concat(args)
            name = enumSensors[0]
        }

        if (rw_mode == 'w') {
            /* emit */ update(name, args)
            main.sensorsMgr.setSensorValue(name, value)
            return
        }


        if(value != old_val) {
            /* emit */ update(name, args)
        } else {
            print("    same value")
        }
    }
}
