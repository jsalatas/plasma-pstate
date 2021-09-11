import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/datasource.js' as Ds


Item {
    id: availableValuesDS
    property var name: "LocalAvailableValues"

    /* required */ property var set_prefs

    signal handleReadAvailResult(string stdout)

    PlasmaCore.DataSource {
        id: datasource
        engine: 'executable'
        readonly property string commandSource: 'pkexec ' + set_prefs + ' -read-available'


        onNewData: {
            if (connectedSources.length) {
                disconnectSource(connectedSources[0])
            }

            if (data['exit code'] > 0) {
                print('monitorAvailableDS error: ' + data.stderr)
            } else {
                handleReadAvailResult(data.stdout)
            }
        }
        Component.onCompleted: {
            connectSource(commandSource);
        }
    }
}
