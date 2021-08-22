import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils
import '../../code/datasource.js' as Ds


PlasmaCore.DataSource {
    id: monitorDS
    engine: 'executable'

    property var name: "LocalMonitor"

    property bool isReady: false
    property string commandSource: (plasmoid.configuration.useSudoForReading ? 'sudo ' : '') +
                                   set_prefs +
                                   (!isReady ? ' -read-all' : ' -read-some ' + sensors_detected.join(" "))

    /* required */ property var set_prefs
    /* required */ property var sensors_model
    /* required */ property var sensors_detected

    /* required */ property var dataSourceReady
    /* required */ property var sensorsValuesChanged


    onNewData: {
        if (data['exit code'] > 0) {
            print('monitorDS error: ' + data.stderr)
        } else {
            var prevIsReady = isReady;
            var args = sourceName.split(' ')
            args = args.slice(args.indexOf(set_prefs) + 1)

            var changes = Ds.handle_read_result(args, data.stdout, monitorDS)

            // Switch command from from -read-all to -read-some
            if (isReady != prevIsReady) {
                disconnectSource(sourceName);
                connectSource(commandSource)
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
