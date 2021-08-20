/*
 *   Copyright 2018 John Salatas <jsalatas@ictpro.gr>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import '../code/utils.js' as Utils

import './DataSourceBackend' as DataSourceBackend
Item {
    id: main
    
    signal sensorsValuesChanged
    signal dataSourceReady
    signal updateSensor(string name, string value)

    FontLoader {
        id: symbolsFont;
        source: '../font/plasma-pstate.ttf'
    }

    property var old_data: {}

    property var monitor_sources: [
        /cpu\/system\/AverageClock/g,
        /cpu\/system\/TotalLoad/g,
        /lmsensors\/.*Package_id_0/g,
        /lmsensors\/.*fan/g
    ]
    property var sensors_model: Utils.get_sensors()
    property var available_values: Utils.get_available_values()
    property var sensors_detected: []

    property alias isReady: monitorDS.isReady
    property bool inTray: (plasmoid.parent === null || plasmoid.parent.objectName === 'taskItemContainer')

    readonly property string set_prefs: '/usr/share/plasma/plasmoids/' +
                                        'gr.ictpro.jsalatas.plasma.pstate/contents/code/' +
                                        'set_prefs.sh'

    property bool passiveMode: plasmoid.configuration.passiveMode
    property int pollingInterval: plasmoid.configuration.passiveMode ? 0:
                                    plasmoid.configuration.pollingInterval ?
                                    (plasmoid.configuration.pollingInterval * 1000) : 2000

    property int sensorInterval: plasmoid.configuration.sensorInterval * 1000

    function sensor_short_name(long_name) {
        var parts = long_name.split('/');
        return parts[parts.length - 1];
    }

    Plasmoid.compactRepresentation: CompactRepresentation { }
    // Plasmoid.fullRepresentation: FullRepresentation { }
    Plasmoid.fullRepresentation: TabbedRepresentation { }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.switchWidth: units.gridUnit * 15
    Plasmoid.switchHeight: units.gridUnit * 20


    Plasmoid.toolTipMainText: '' //i18n('Intel pstate and Thermal Management')
    Plasmoid.toolTipSubText: ''
    Plasmoid.toolTipTextFormat: Text.RichText
    Plasmoid.icon: ''

    Component.onCompleted: {
        if (!inTray) {
            // not in tray
        }
    }

    onUpdateSensor: {
        print("updating sensor " + name +": " + value)

        var rw_mode = sensors_model[name]['rw_mode']
        var old_val = sensors_model[name]['value']

        if (rw_mode == 'w') {
            updater.update(name, value)
            sensors_model[name]['value'] = value
            sensorsValuesChanged();
            return
        }

        if(value != old_val) {
            updater.update(name, value)
        } else {
            print("    same value")
        }
    }

    function get_value_text(sensor, value) {
        // lol! Is this the bwsat way to do it?
        var obj = {'value': value, 'unit': sensors_model[sensor]['unit']}
        return sensors_model[sensor]['print'](obj)
    }

    function get_sensors_text(sensors) {
        var res = '';
        if(sensors != undefined) {
            for(var i = 0 ; i < sensors.length; i++) {
                var value = sensors_model[sensors[i]]['print'](sensors_model[sensors[i]]);
                if(value) {
                    if(res) {
                        res += ' | ';
                    }
                    res += value;
                }
            }
        }

        return res || 'N/A';
    }

    function monitor_source(src) {
        for(var i=0; i < monitor_sources.length; i++) {
            if(src.match(monitor_sources[i])) {
                return true;
            }
        }

        return false;
    }

    onSensorsValuesChanged: {
        updateTooltip();
    }

    PlasmaCore.DataSource {
        id: systemmonitorDS
        engine: 'systemmonitor'
        property var timestamp: Date.now()

        onSourceAdded: {
             if(monitor_source(source)) {
                 if(connectedSources.indexOf(source) == -1) {
                    connectSource(source);
                 }
            }
        }

        onNewData: {
            var source_short_name = sensor_short_name(sourceName);
            var changes = false

            if(source_short_name.startsWith('fan')) {
                if (sensors_model['fan_speeds'] != undefined &&
                    sensors_model['fan_speeds']['value'] != undefined)
                {
                    changes = changes || sensors_model['fan_speeds']['value'][source_short_name] != data.value;
                    sensors_model['fan_speeds']['value'][source_short_name] = data.value;
                }
            } else {
                switch (source_short_name) {
                    case 'AverageClock': {
                        changes = changes || sensors_model['cpu_cur_freq']['value'] != data.value
                        sensors_model['cpu_cur_freq']['value'] = data.value
                        break;
                    }
                    case 'Package_id_0': {
                        changes = changes || sensors_model['package_temp']['value'] != data.value
                        sensors_model['package_temp']['value'] = data.value
                        break;
                    }
                    case 'TotalLoad': {
                        changes = changes || sensors_model['cpu_cur_load']['value'] != data.value
                        sensors_model['cpu_cur_load']['value'] = data.value
                        break;
                    }
                }
            }

            if (passiveMode || changes) {
                sensorsChanged()
            }
        }
        interval: sensorInterval

        function sensorsChanged() {
           var t = Date.now()
            var dt = t - timestamp
            if (dt >= interval) {
                sensorsValuesChanged()
                timestamp = t
            }
        }
    }

    PlasmaCore.DataSource {
        id: powermanagementDS
        engine: "powermanagement"
        connectedSources: ['Battery']
        onDataChanged: {
            if(powermanagementDS.data["Battery"]) {
                var bat_time = Number(powermanagementDS.data["Battery"]["Remaining msec"]) / 1000;
                sensors_model['battery_remaining_time']['value'] = bat_time;
                var bat_charge = powermanagementDS.data["Battery"]["Percent"];
                sensors_model['battery_percentage']['value'] = bat_charge;
            }
        }
        interval: sensorInterval
    }

    Connections {
        target: plasmoid.configuration
        onUseSudoForReadingChanged: {
            if (passiveMode === false) {
                monitorDS.restart()
            }
        }

        onPollingIntervalChanged: {
            monitorDS.stop()
            monitorDS.interval = pollingInterval
            monitorDS.start()
        }

        onPassiveModeChanged: {
            if (passiveMode == true) {
                monitorDS.stop()
                monitorDS.interval = 0
            } else if (passiveMode == false) {
                monitorDS.interval = pollingInterval
                monitorDS.start()
            }
        }

        onSensorIntervalChanged: {
            systemmonitorDS.interval = sensorInterval
            powermanagementDS.interval = sensorInterval
        }
    }

    DataSourceBackend.Monitor {
        id: monitorDS

        set_prefs: main.set_prefs
        sensors_model: main.sensors_model
        sensors_detected: main.sensors_detected
        dataSourceReady: main.dataSourceReady
        sensorsValuesChanged: main.sensorsValuesChanged
    }

    DataSourceBackend.Updater {
        id: updater
        set_prefs: main.set_prefs
        sensors_model: main.sensors_model
        sensors_detected: main.sensors_detected
        sensorsValuesChanged: main.sensorsValuesChanged
    }

    DataSourceBackend.AvailableValues {
        commandSource: (plasmoid.configuration.useSudoForReading ? 'sudo ' : '') +
                       set_prefs + ' -read-available'

        available_values: main.available_values
        dataSourceReady: main.dataSourceReady
        isReady: function() { return main.isReady }
    }

    NvidiaPowerMizerDS {
        id: nvidiaPowerMizerDS
        sensors_model: main.sensors_model
        dataSourceReady: main.dataSourceReady
    }


    PlasmaCore.DataSource {
        id: notificationSource
        engine: "executable"

        onNewData: {
            disconnectSource(sourceName)
        }
        function createNotification(msg) {
            var cmd = ["notify-send"]
            cmd.push("-u", "normal")
            cmd.push("-t", "5000")
            cmd.push("-a", "\"P-state and CPUFreq Manager\"")
            cmd.push("-i", "cpu")
            cmd.push("-c", "hardware")
            cmd.push("\""+msg+"\"")
            print(cmd.join(" "))
            connectSource(cmd.join(" "))
        }
    }


    function updateTooltip() {
        var toolTipSubText ='';
        var txt = '';

        toolTipSubText += '<font size="4"><table>'

        toolTipSubText += '<tr>'
        toolTipSubText += '<td style="text-align: right;">'
        toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">d</font></span>'
        toolTipSubText += '</td>'
        toolTipSubText += '<td style="text-align: left;">'
        toolTipSubText += '<span>&nbsp;&nbsp;'+get_sensors_text(['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'])+'</span>'
        toolTipSubText += '</td>'
        toolTipSubText += '</tr>'

        txt = get_sensors_text(['battery_percentage', 'battery_remaining_time']);
        if(txt != 'N/A') {
            toolTipSubText += '<tr>'
            toolTipSubText += '<td style="text-align: center;">'
            toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">h</font></span>'
            toolTipSubText += '</td>'
            toolTipSubText += '<td style="text-align: left;">'
            toolTipSubText += '<span>&nbsp;&nbsp;'+ txt +'</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '</tr>'
        }

        txt = get_sensors_text(['package_temp', 'fan_speeds']);
        if (txt != 'N/A') {
            toolTipSubText += '<tr>'
            toolTipSubText += '<td style="text-align: center;">'
            toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">b</font></span>'
            toolTipSubText += '</td>'
            toolTipSubText += '<td style="text-align: left;">'
            toolTipSubText += '<span>&nbsp;&nbsp;'+ txt +'</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '</tr>'
        }
        toolTipSubText += '</table></font>'

        Plasmoid.toolTipSubText = toolTipSubText
    }
}
