/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.3

import '../code/utils.js' as Utils
import '../code/datasource.js' as Ds


Item {
    id: manager

    /* required */ property var available_values
    /* required */ property var sensors_detected

    signal setPrefsReady
    signal update(string parameter, string value)


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
            Ds.initSensorsDetected(main.sensorsMgr, sensors_detected)
            print("sensors_detected: ", sensors_detected)

            hasReadSensors = true;
            doFirstInit();
        }
    }

    // Parse the result of "set_prefs.sh -read-available"
    function handleReadAvailResult(stdout) {
        var obj = JSON.parse(stdout);
        var keys = Object.keys(obj);
        for (var i=0; i < keys.length; i++) {
            var d = obj[keys[i]]
            var values = d.split(' ').filter(item => item.length > 0)
            available_values[keys[i]] = values
        }

        print("available_values: ", JSON.stringify(available_values))

        hasReadAvailable = true;
        doFirstInit();
    }

    function handleSetValueResult(arg, stdout) {
        var arg_0 = arg
        arg_0 = arg_0.substring(1)
                     .split('-').join('_')
        if (sensors_detected.includes(arg_0)) {
            var obj = JSON.parse(stdout);

            Ds.parseSensorData(obj, undefined, true)
        }
    }


    function updateSensor(name, value) {
        print("updating sensor " + name +": " + value)

        var sensorModel = main.sensorsMgr.getSensor(name)
        var rw_mode = sensorModel.rw_mode
        var old_val = sensorModel.value

        if (rw_mode == 'w') {
            /* emit */ update(name, value)
            main.sensorsMgr.setSensorValue(name, value)
            return
        }


        if(value != old_val) {
            /* emit */ update(name, value)
        } else {
            print("    same value")
        }
    }
}
