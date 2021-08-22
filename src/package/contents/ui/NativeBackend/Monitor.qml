import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils
import '../../code/datasource.js' as Ds


Item {
    id: nativeMonitor
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
                var changes = Ds.handle_read_result(args, data.stdout, nativeMonitor)
                return
            }

            if (args[0] === '-read-available') {
                Ds.handle_read_avail_result(data.stdout, nativeMonitor)
                return
            }

            Ds.handle_set_value(args[0], data.stdout, nativeMonitor)
        }
    }

    Component.onCompleted: {
        plasmoid.nativeInterface.setPrefs(['-read-available'])
    }
}
