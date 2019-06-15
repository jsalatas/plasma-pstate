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
import QtQuick.Controls 1.0 as QtControls

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

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

    property var monitor_sources: [/cpu\/system\/AverageClock/g, /cpu\/system\/TotalLoad/g, /lmsensors\/.*Package_id_0/g, /lmsensors\/.*fan/g]
    property var sensors_model: Utils.get_sensors()
    property alias isReady: monitorDS.isReady
    property bool inTray: (plasmoid.parent === null || plasmoid.parent.objectName === 'taskItemContainer')

    function sensor_short_name(long_name) {
        var parts = long_name.split('/');
        return parts[parts.length - 1];
    }

    Plasmoid.compactRepresentation: CompactRepresentation { }
    Plasmoid.fullRepresentation: FullRepresentation { }

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
        property var seenSources: []

        onSourceAdded: {
             if(monitor_source(source)) {
                 if(systemmonitorDS.connectedSources.indexOf(source) == -1) {
                     systemmonitorDS.connectedSources.push(source);
                 }
            }
        }

        onNewData: {
            var show = false
            if(systemmonitorDS.seenSources.indexOf(sourceName) == -1 && data.value != undefined) {
                systemmonitorDS.seenSources.push(sourceName)
            }

            var source_short_name = sensor_short_name(sourceName);

            if(source_short_name.startsWith('fan')) {
                if (sensors_model['fan_speeds'] != undefined && sensors_model['fan_speeds']['value'] != undefined) {
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

        Component.onCompleted: {
            systemmonitorDS.connectedSources = [];
            systemmonitorDS.connectedSources.length = 0;

            for(var i=0; i< systemmonitorDS.sources.length; i++) {
                if(monitor_source(systemmonitorDS.sources[i])) {
                    if(systemmonitorDS.connectedSources.indexOf(systemmonitorDS.sources[i]) == -1) {
                        systemmonitorDS.connectedSources.push(systemmonitorDS.sources[i]);
                    }
                }
            }
        }
        interval: 2000
    }

    PlasmaCore.DataSource {
        id: powermanagementDS
        engine: "powermanagement"
        connectedSources: ['Battery']
        onDataChanged: {
            if(powermanagementDS.data["Battery"]) {
                sensors_model['battery_remaining_time']['value'] = Number(powermanagementDS.data["Battery"]["Remaining msec"]) / 1000;
                sensors_model['battery_percentage']['value'] = powermanagementDS.data["Battery"]["Percent"];
                sensorsValuesChanged()
            }
        }
        interval: 2000
    }

    Connections {
        target: plasmoid.configuration
        onUseSudoForReadingChanged: {
            monitorDS.commandSource = (plasmoid.configuration.useSudoForReading ? 'sudo ' : '') + '/usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh -read-all'
            monitorDS.connectedSources = [];
            monitorDS.connectedSources.length = 0;
            monitorDS.connectedSources.push(monitorDS.commandSource);
        }
    }

    PlasmaCore.DataSource {
        id: monitorDS
        engine: 'executable'

        property bool isReady: false
        property string commandSource: (plasmoid.configuration.useSudoForReading ? 'sudo ' : '') + '/usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh -read-all'

        onNewData: {
            if (data['exit code'] > 0) {
                print('monitorDS error: ' + data.stderr)
            } else {
                var obj = JSON.parse(data.stdout);
                var keys = Object.keys(obj);
                for(var i=0; i< keys.length; i++) {
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
            monitorDS.connectedSources = [];
            monitorDS.connectedSources.length = 0;
            monitorDS.connectedSources.push(monitorDS.commandSource);

        }
        interval: 2000
    }

    PlasmaCore.DataSource {
        id: updater
        engine: 'executable'

        property string commandSource: 'sudo /usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh -'

        onNewData: {
            updater.connectedSources = []
            updater.connectedSources.length = 0
            if (data['exit code'] > 0) {
                print("    error: " + data.stderr)
            } else {
                print("    done")
            }
        }
        Component.onCompleted: {
            updater.connectedSources = [];
            updater.connectedSources.length = 0;
        }
        function update(parameter, value) {
            var command = updater.commandSource + parameter.replace(/_/g, '-') + ' ' + value
            print("exec: " + command)
            updater.connectedSources.push(command);

        }
    }

    function updateTooltip() {
        var toolTipSubText ='';
        var txt = '';

        toolTipSubText += '<table>'

        toolTipSubText += '<tr>'
        toolTipSubText += '<td style="text-align: right;">'
        toolTipSubText += '<span style="font-family: Plasma pstate Manager;font-size: 32px;">d</span>'
        toolTipSubText += '</td>'
        toolTipSubText += '<td style="text-align: left;">'
        toolTipSubText += '<span style="font-size: 22px;">&nbsp;&nbsp;'+get_sensors_text(['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'])+'</span>'
        toolTipSubText += '</td>'
        toolTipSubText += '</tr>'

        txt = get_sensors_text(['battery_percentage', 'battery_remaining_time']);
        if(txt != 'N/A') {
            toolTipSubText += '<tr>'
            toolTipSubText += '<td style="text-align: center;">'
            toolTipSubText += '<span style="font-family: Plasma pstate Manager;font-size: 32px;">h</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '<td style="text-align: left;">'
            toolTipSubText += '<span style="font-size: 22px;">&nbsp;&nbsp;'+ txt +'</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '</tr>'
        }

        txt = get_sensors_text(['package_temp', 'fan_speeds']);
        if (txt != 'N/A') {
            toolTipSubText += '<tr>'
            toolTipSubText += '<td style="text-align: center;">'
            toolTipSubText += '<span style="font-family: Plasma pstate Manager;font-size: 32px;">b</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '<td style="text-align: left;">'
            toolTipSubText += '<span style="font-size: 22px;">&nbsp;&nbsp;'+ txt +'</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '</tr>'
        }
        toolTipSubText += '</table>'

        Plasmoid.toolTipSubText = toolTipSubText
    }
}
