import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils


PlasmaCore.DataSource {
    id: monitorDS
    engine: 'executable'

    property var name: "LocalMonitor"

    property bool isReady: false
    property string commandSource: (plasmoid.configuration.useSudoForReading ? 'sudo ' : '') +
                                   set_prefs +
                                   (!isReady ? ' -read-all' : ' -read-some ' + sensors_detected.join(" "))

    required property var set_prefs
    required property var sensors_model
    required property var sensors_detected

    required property var dataSourceReady
    required property var sensorsValuesChanged


    onNewData: {
        if (data['exit code'] > 0) {
            print('monitorDS error: ' + data.stderr)
        } else {
            var obj = JSON.parse(data.stdout);

            Utils.remove_stale_data(obj, old_data, sensors_model);
            old_data = obj

            var changes = Utils.parse_sensor_data(obj)

            if(!isReady) {
                sensors_detected = Utils.init_sensors_detected(sensors_model);
                print("sensors_detected: ", sensors_detected)
                disconnectSource(sourceName)

                dataSourceReady();
                isReady = true;

                connectSource(commandSource)
            }

            if (changes) {
                sensorsValuesChanged();
            }
        }
    }

    Component.onCompleted: {
        connectSource(commandSource);
    }
    interval: pollingInterval

    function restart() {
        stop()
        start()
    }

    function stop() {
        while(connectedSources.length) {
            disconnectSource(connectedSources[0]);
        }
    }

    function start() {
        connectSource(commandSource);
    }
}
