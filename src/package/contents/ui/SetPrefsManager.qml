import QtQuick 2.3

import '../code/utils.js' as Utils
import '../code/datasource.js' as Ds


Item {
    id: manager

    /* required */ property var sensors_model
    /* required */ property var available_values
    /* required */ property var sensors_detected

    signal sensorsValuesChanged
    signal setPrefsReady


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

        var changes = Ds.parse_sensor_data(obj, args.splice(1))

        if(!hasReadSensors) {
            Ds.init_sensors_detected(sensors_model, sensors_detected);
            print("sensors_detected: ", sensors_detected)

            hasReadSensors = true;
            doFirstInit();
        }

        if (changes) {
            sensorsValuesChanged();
        }

        return changes
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

        hasReadAvailable = true;
        doFirstInit();
    }

    function handleSetValueResult(arg, stdout) {
        var arg_0 = arg
        arg_0 = arg_0.substring(1)
                     .split('-').join('_')
        if (sensors_detected.includes(arg_0)) {
            var obj = JSON.parse(stdout);
            var changes = Ds.parse_sensor_data(obj)
            sensorsValuesChanged();
        }
    }
}