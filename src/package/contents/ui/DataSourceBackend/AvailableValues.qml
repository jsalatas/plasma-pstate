import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import '../../code/datasource.js' as Ds


Item {
    id: availableValuesDS
    property var name: "LocalAvailableValues"

    /* required */ property string commandSource
    /* required */ property var available_values
    /* required */ property var dataSourceReady
    /* required */ property var isReady


    PlasmaCore.DataSource {
        id: datasource
        engine: 'executable'
        property alias commandSource: availableValuesDS.commandSource


        onNewData: {
            if (connectedSources.length) {
                disconnectSource(connectedSources[0])
            }

            if (data['exit code'] > 0) {
                print('monitorAvailableDS error: ' + data.stderr)
            } else {
                Ds.handle_read_avail_result(data.stdout, availableValuesDS)

                print(JSON.stringify(available_values))
            }
        }
        Component.onCompleted: {
            connectSource(commandSource);
        }
    }
}
