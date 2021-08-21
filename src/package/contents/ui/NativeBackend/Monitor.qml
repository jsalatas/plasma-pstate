import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils


Item {
    property var name: "NativeMonitor"
    property bool isReady: false

    /* required */ property var sensors_model
    /* required */ property var sensors_detected
    /* required */ property var available_values

    /* required */ property var dataSourceReady
    /* required */ property var sensorsValuesChanged

    //
    // proxy the inner timer object
    //
    function start() { timer.start() }
    function stop() { timer.stop() }
    function restart() { timer.restart() }

    property alias interval: timer.interval
    property alias running: timer.running
    property alias repeat: timer.repeat
    property alias triggeredOnStart: timer.triggeredOnStart


    Timer {
        id: timer
        onTriggered: {
            var args = !isReady ? ['-read-all'] : ['-read-some'].concat(sensors_detected)
            plasmoid.nativeInterface.setPrefs(args)
        }
    }

    Connections {
        target: main
        onDataSourceReady: {
            isReady = true
        }
    }

    Connections {
        target: plasmoid.nativeInterface

        function debugPrint(data) {
            var obj = JSON.parse(data.stdout)
            var keys = Object.keys(obj)
            for (var i=0; i< keys.length; i++) {
                print(keys[i], " = ", obj[keys[i]])
            }
        }

        onCommandFinished: {
            var exitCode = data.exitCode
            var args = data.args

            if (exitCode != 0) {
                print('error: ' + data.stderr)
                return
            }

            if (args.length == 0) {
                print('error: Command result with no args.')
                return
            }

            if (args[0] === '-read-all' || args[0] === '-read-some') {
                var obj = JSON.parse(data.stdout);

                Utils.remove_stale_data(obj, old_data, sensors_model);
                old_data = obj

                var changes = Utils.parse_sensor_data(obj)

                if(!isReady) {
                    sensors_detected = Utils.init_sensors_detected(sensors_model);
                    print("sensors_detected: ", sensors_detected)

                    dataSourceReady();
                    isReady = true;
                }

                if (changes) {
                    sensorsValuesChanged();
                }

                return
            }

            if (args[0] === '-read-available') {
                var obj = JSON.parse(data.stdout);
                var keys = Object.keys(obj);
                for (var i=0; i < keys.length; i++) {
                    var d = obj[keys[i]]
                    var values = d.split(' ').filter(item => item.length > 0)
                    available_values[keys[i]] = values
                }

                if (isReady) {
                    dataSourceReady();
                }
                return
            }

            // Parse the result after setting a value
            var arg_0 = args[0]
            arg_0 = arg_0.substring(1)
                         .split('-').join('_')
             if (sensors_detected.includes(arg_0)) {
                var obj = JSON.parse(data.stdout);
                var changes = Utils.parse_sensor_data(obj)
                sensorsValuesChanged();
             }
        }
    }

    Component.onCompleted: {
        plasmoid.nativeInterface.setPrefs(['-read-available'])
    }
}
