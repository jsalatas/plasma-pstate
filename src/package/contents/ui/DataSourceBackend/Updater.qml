import QtQuick 2.3
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/utils.js' as Utils
import '../../code/datasource.js' as Ds


PlasmaCore.DataSource {

    id: updater
    engine: 'executable'

    property string name: "LocalUpdater"

    readonly property string commandSource: 'pkexec ' + set_prefs

    /* required */ property var set_prefs

    signal handleSetValueResult(var arg, string stdout)

    onNewData: {
        disconnectSource(sourceName)

        if (data['exit code'] > 0) {
            print("    error: " + data.stderr)
            notify(sourceName)
        } else {
            var cmd = sourceName.split(' ')[2]
            handleSetValueResult(cmd, data.stdout)

            print("    done")
        }

        // monitorDS.start()
    }
    function update(sensor, args) {
        // monitorDS.stop()

        var command = [" -write-sensor", sensor]
        command = commandSource + command.concat(args).join(' ')

        print("exec: " + command)
        connectSource(command);

        if (sensor === 'powermizer') {
            nvidiaPowerMizerDS.update()
        }
    }
    function notify(sourceName) {
        var args = sourceName.replace(commandSource, "").split(" ")
        var sensorModel = main.sensorsMgr.getSensor(args[1])
        var value = sensorModel.getValueText()
        notificationSource.createNotification("Failed to set " + sensor + " to " + value)
    }
}
