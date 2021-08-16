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

    property var monitor_sources: [/cpu\/system\/AverageClock/g, /cpu\/system\/TotalLoad/g, /lmsensors\/.*Package_id_0/g, /lmsensors\/.*fan/g]
    property var sensors_model: Utils.get_sensors()
    property alias isReady: monitorDS.isReady
    property bool inTray: (plasmoid.parent === null || plasmoid.parent.objectName === 'taskItemContainer')
    property var readCommand: (plasmoid.configuration.useSudoForReading ? 'sudo ' : '') + '/usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh -read-all'

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
        if(value != sensors_model[name]['value']) {
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

        onSourceAdded: {
             if(monitor_source(source)) {
                 if(connectedSources.indexOf(source) == -1) {
                    connectSource(source);
                 }
            }
        }

        onNewData: {
            var source_short_name = sensor_short_name(sourceName);

            if(source_short_name.startsWith('fan')) {
                if (sensors_model['fan_speeds'] != undefined &&
                    sensors_model['fan_speeds']['value'] != undefined)
                {
                    sensors_model['fan_speeds']['value'][source_short_name] = data.value;
                }
            } else {
                switch (source_short_name) {
                    case 'AverageClock': {
                        sensors_model['cpu_cur_freq']['value'] = data.value
                        break;
                    }
                    case 'Package_id_0': {
                        sensors_model['package_temp']['value'] = data.value
                        break;
                    }
                    case 'TotalLoad': {
                        sensors_model['cpu_cur_load']['value'] = data.value
                        break;
                    }
                }
            }

            sensorsValuesChanged()
        }
        interval: 2000
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
                sensorsValuesChanged()
            }
        }
        interval: 2000
    }

    Connections {
        target: plasmoid.configuration
        onUseSudoForReadingChanged: {
            while(monitorDS.connectedSources.length) {
                monitorDS.disconnectSource(monitorDS.connectedSources[0]);
            }
            monitorDS.commandSource = readCommand
            monitorDS.connectSource(monitorDS.commandSource);
        }
    }

    PlasmaCore.DataSource {
        id: monitorDS
        engine: 'executable'

        property bool isReady: false
        property string commandSource: readCommand

        onNewData: {
            if (data['exit code'] > 0) {
                print('monitorDS error: ' + data.stderr)
            } else {
                var obj = JSON.parse(data.stdout);

                Utils.remove_stale_data(obj, old_data, sensors_model);
                old_data = obj

                var keys = Object.keys(obj);
                for(var i=0; i< keys.length; i++) {
                    if (!sensors_model[keys[i]]) {
                        continue;
                    }
                    sensors_model[keys[i]]['value'] = obj[keys[i]];
                }
                if(!isReady) {
                    dataSourceReady();
                    isReady = true;
                }
                sensorsValuesChanged();
            }
        }
        Component.onCompleted: {
            connectSource(commandSource);
        }
        interval: 2000
    }

    PlasmaCore.DataSource {
        id: updater
        engine: 'executable'

        property string commandSource: 'sudo /usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh -'

        onNewData: {
            disconnectSource(sourceName)

            if (data['exit code'] > 0) {
                print("    error: " + data.stderr)
            } else {
                print("    done")
            }
        }
        function update(parameter, value) {
            var command = commandSource + parameter.replace(/_/g, '-') + ' ' + value
            print("exec: " + command)
            connectSource(command);

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
