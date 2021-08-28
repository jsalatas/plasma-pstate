
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

function parse_sensor_data(obj, expected_sensors) {
    var keys = Object.keys(obj);
    var orig_keys = keys;

    if (expected_sensors) {
        keys = array_unique(keys.concat(expected_sensors))
    }

    var changes = false
    for(var i=0; i< keys.length; i++) {
        if (!sensors_model[keys[i]]) {
            continue;
        }

        // Clear sensor value that didn't report data
        if (orig_keys.indexOf(keys[i]) == -1) {
            sensors_model[keys[i]]['value'] = undefined
            continue
        }

        var rw_mode = sensors_model[keys[i]]['rw_mode']
        var old_val = sensors_model[keys[i]]['value']

        if (rw_mode == 'w') {
            changes = changes || sensors_model[keys[i]]['value'] !== obj[keys[i]]
        }

        sensors_model[keys[i]]['value'] = obj[keys[i]];
    }

    return changes
}

function init_sensors_detected(sensors_model, sensors_detected) {
    var keys = Object.keys(sensors_model);
    for (var i = 0; i < keys.length; i++) {
        var sensor = sensors_model[keys[i]]
        if (sensor['value'] !== undefined &&
            !sensors_detected.includes(keys[i]) &&
            !Utils.is_sysmon_sensor(sensor))
        {
            sensors_detected.push(keys[i])
        }
    }
}


function filter_readable_sensors(sensors_detected) {
    var readable = []
    for (var i = 0; i < sensors_detected.length; i++) {
        var sensor = sensors_detected[i]
        if (!(sensor in sensors_model)) {
            continue
        }

        // undefined rw_mode defaults to readable
        if (!('rw_mode' in sensors_model[sensor])) {
            readable.push(sensor)
            continue
        }

        var rw_mode = sensors_model[sensor]['rw_mode']
        if (rw_mode === 'r') {
            readable.push(sensor)
            continue
        }
    }
    return readable
}
