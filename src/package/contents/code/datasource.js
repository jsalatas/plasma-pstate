
.import "utils.js" as Utils

function array_unique(a) {
    for(var i=0; i<a.length; ++i) {
        for(var j=i+1; j<a.length; ++j) {
            if(a[i] === a[j])
                a.splice(j--, 1);
        }
    }
    return a;
}


function filterReadableSensors(detectedSensors) {
    var readable = []

    var sensorNames = main.sensorsMgr.getKeys()

    for (var i = 0; i < detectedSensors.length; i++) {
        var sensor = detectedSensors[i]
        if (!sensorNames.includes(sensor)) {
            continue
        }

        var sensorModel = main.sensorsMgr.getSensor(sensor)

        // undefined rw_mode defaults to readable
        if (sensorModel.rw_mode === undefined) {
            readable.push(sensor)
            continue
        }

        if (sensorModel.rw_mode === 'r') {
            readable.push(sensor)
            continue
        }
    }
    return readable
}

function parseSensorData(obj, expected_sensors, force_update) {
    var keys = Object.keys(obj);
    var orig_keys = keys;
    if (!main.sensorsMgr) {
        return false
    }

    if (expected_sensors) {
        keys = array_unique(keys.concat(expected_sensors))
    }

    for(var i=0; i< keys.length; i++) {
        if (!main.sensorsMgr.hasKey(keys[i])) {
            continue;
        }

        var sensorModel = main.sensorsMgr.getSensor(keys[i])

        // Clear sensor value that didn't report data
        if (orig_keys.indexOf(keys[i]) == -1) {
            sensorModel.value = undefined
            continue
        }

        var rw_mode = sensorModel.rw_mode
        var old_val = sensorModel.value

        if (rw_mode == 'w') {
            sensorModel.value !== obj[keys[i]]
        }

        if (force_update || obj[keys[i]] !== sensorModel.value) {
            sensorModel.value = obj[keys[i]];
        }
    }
}
