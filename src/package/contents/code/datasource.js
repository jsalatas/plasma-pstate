
.import "utils.js" as Utils

function remove_stale_data(data, old_data, sensors_model) {
    var has_stale_data = false;

    let diff = old_data.filter(x => !data.includes(x));

    for (var i=0; i < diff.length; i++) {
        if (!(diff[i] in sensors_model)) {
            continue
        }
        sensors_model[diff[i]].value = undefined
        has_stale_data = true;
    }

    return has_stale_data;
}

function parse_sensor_data(obj) {
    var keys = Object.keys(obj);
    var changes = false
    for(var i=0; i< keys.length; i++) {
        if (!sensors_model[keys[i]]) {
            continue;
        }

        var rw_mode = sensors_model[keys[i]]['rw_mode']
        var old_val = sensors_model[keys[i]]['value']
        if (rw_mode == 'w'){
            if (old_val === undefined) {
                sensors_model[keys[i]]['value'] = true
            }
        } else {
            changes = changes || sensors_model[keys[i]]['value'] !== obj[keys[i]]
            sensors_model[keys[i]]['value'] = obj[keys[i]];
        }
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
