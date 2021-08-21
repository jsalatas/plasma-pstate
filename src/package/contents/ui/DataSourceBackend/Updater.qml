import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils


PlasmaCore.DataSource {

    id: updater
    engine: 'executable'

    property var name: "LocalUpdater"

    readonly property string commandSource: 'sudo ' + set_prefs + ' -'

    /* required */ property var set_prefs
    /* required */ property var sensors_model
    /* required */ property var sensors_detected
    /* required */ property var sensorsValuesChanged


    onNewData: {
        disconnectSource(sourceName)

        if (data['exit code'] > 0) {
            print("    error: " + data.stderr)
            notify(sourceName)
        } else {
            var obj = JSON.parse(data.stdout);
            var changes = Utils.parse_sensor_data(obj)
            sensorsValuesChanged();
            print("    done")
        }

        // monitorDS.start()
    }
    function update(parameter, value) {
        // monitorDS.stop()

        var command = commandSource + parameter.replace(/_/g, '-') + ' ' + value
        print("exec: " + command)
        connectSource(command);

        if (parameter === 'powermizer') {
            nvidiaPowerMizerDS.update()
        }
    }
    function notify(sourceName) {
        var args = sourceName.replace(commandSource, "").split(" ")
        var sensor = args[0].replace(/-/g, '_')
        var value = get_value_text(sensor, args[1])
        notificationSource.createNotification("Failed to set " + sensor + " to " + value)
    }
}
