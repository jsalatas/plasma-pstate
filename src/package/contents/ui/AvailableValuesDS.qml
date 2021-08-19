import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: availableValuesDS
    property string commandSource: undefined

    property var available_values
    property var dataSourceReady
    property var isReady


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
                var obj = JSON.parse(data.stdout);
                var keys = Object.keys(obj);
                for (var i=0; i < keys.length; i++) {
                    var data = obj[keys[i]]
                    var values = data.split(' ').filter(item => item.length > 0)
                    available_values[keys[i]] = values
                }

                if (isReady) {
                    dataSourceReady();
                }
            }
        }
        Component.onCompleted: {
            connectSource(commandSource);
        }
    }
}
