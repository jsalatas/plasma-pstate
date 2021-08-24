/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import '../code/utils.js' as Utils

import './DataSourceBackend' as DataSourceBackend
import './NativeBackend' as NativeBackend

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

    property var updater: undefined
    property var monitorDS: undefined

    property var sensors_model: Utils.get_sensors()
    property var available_values: Utils.get_available_values()
    property var sensors_detected: []

    property bool inTray: (plasmoid.parent === null || plasmoid.parent.objectName === 'taskItemContainer')

    property bool hasNativeBackend: plasmoid.nativeInterface.isReady !== undefined

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


    Plasmoid.fullRepresentation: TabbedRepresentation {
        Component.onCompleted: {
            firstInit.viewReady()
        }
    }


    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.switchWidth: units.gridUnit * 15
    Plasmoid.switchHeight: units.gridUnit * 20

    property var toolTipMainText
    property var toolTipSubText
    property var toolTipTextFormat
    property var icon

    Component.onCompleted: {
        if (!inTray) {
            // not in tray
        }
    }

    FirstInit {
        id: firstInit
        Component.onCompleted: {
            firstInit.beginStageOne.connect(onBeginStageOne)
            firstInit.beginStageTwo.connect(onBeginStageTwo)
            firstInit.initialized.connect(main.dataSourceReady)
            firstInit.initialized.connect(main.initialized)
            /* emit */ firstInit.beginStageOne()
        }

        function onBeginStageOne() {
            if (main.hasNativeBackend) {
                nativeBackendInit.init(firstInit.scriptReady)
            }
        }

        function onBeginStageTwo() {
            if (main.hasNativeBackend) {
                main.monitorDS.init()
            }
        }
    }

    NativeBackend.Init {
        id: nativeBackendInit
        hasNativeBackend: main.hasNativeBackend
    }

    function initialized() {
        main.updateSensor.connect(prefsManager.updateSensor)
        prefsManager.update.connect(updater.update)

        toolTipMainText = plasmoid.toolTipMainText
        toolTipSubText = plasmoid.toolTipSubText
        toolTipTextFormat = plasmoid.toolTipTextFormat
        icon = plasmoid.icon

        if (plasmoid.configuration.monitorWhenHidden) {
            useCustomToolTip()
        } else {
            stopMonitors()
        }
    }

    function startMonitors() {
        powermanagementDS.start()
        systemmonitorDS.start()
        monitorDS.start()
    }

    function stopMonitors() {
        powermanagementDS.stop()
        systemmonitorDS.stop()
        monitorDS.stop()
    }

    function useOriginalToolTip() {
        Plasmoid.toolTipMainText = toolTipMainText
        Plasmoid.toolTipSubText = toolTipSubText
        Plasmoid.toolTipTextFormat = toolTipTextFormat
        // Plasmoid.icon = icon
    }

    function useCustomToolTip() {
        Plasmoid.toolTipMainText = ''
        Plasmoid.toolTipSubText = ''
        Plasmoid.toolTipTextFormat = Text.RichText
        // Plasmoid.icon = ''
        updateTooltip()
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

        property var sources: []

        onSourceAdded: {
             if(monitor_source(source)) {
                 if(connectedSources.indexOf(source) == -1) {
                    connectSource(source);
                    sources.push(source)
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

        function start() {
            sources.forEach(source => {
                if (connectedSources.indexOf(source) === -1) {
                    connectSource(source)
                }
            })
        }

        function stop() {
            sources.forEach(source => {
                if (connectedSources.indexOf(source) !== -1) {
                    disconnectSource(source)
                }
            })
        }
    }

    PlasmaCore.DataSource {
        id: powermanagementDS
        engine: "powermanagement"
        onDataChanged: {
            if(powermanagementDS.data["Battery"]) {
                var bat_time = Number(powermanagementDS.data["Battery"]["Remaining msec"]) / 1000;
                sensors_model['battery_remaining_time']['value'] = bat_time;
                var bat_charge = powermanagementDS.data["Battery"]["Percent"];
                sensors_model['battery_percentage']['value'] = bat_charge;
            }
        }
        interval: sensorInterval

        property var sources: ['Battery']

        function start() {
            sources.forEach(source => {
                if (connectedSources.indexOf(source) === -1) {
                    connectSource(source)
                }
            })
        }

        function stop() {
            sources.forEach(source => {
                if (connectedSources.indexOf(source) !== -1) {
                    disconnectSource(source)
                }
            })
        }
    }

    Connections {
        target: plasmoid
        function onExpandedChanged() {
            if (!plasmoid.configuration.monitorWhenHidden) {
                if (plasmoid.expanded) {
                    startMonitors()
                } else {
                    stopMonitors()
                }
            }
        }
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

        onMonitorWhenHiddenChanged: {
            if (!plasmoid.configuration.monitorWhenHidden) {
                stopMonitors()
                useOriginalToolTip()
            } else {
                startMonitors()
                useCustomToolTip()
            }
        }
    }

    SetPrefsManager {
        id: prefsManager

        sensors_model: main.sensors_model
        sensors_detected: main.sensors_detected
        available_values: main.available_values

        Component.onCompleted: {
            prefsManager.setPrefsReady.connect(firstInit.dataReady)
            prefsManager.sensorsValuesChanged.connect(main.sensorsValuesChanged)
        }
    }

    Item {
        Loader {
            id: monitorLoader
            onLoaded: {
                print("monitorLoader: loaded " + monitorLoader.item.name)
                main.monitorDS = monitorLoader.item
                monitorDS.handleReadResult
                    .connect(prefsManager.handleReadResult)
                if (hasNativeBackend) {
                    monitorDS.handleReadAvailResult
                        .connect(prefsManager.handleReadAvailResult)
                    monitorDS.handleSetValueResult
                        .connect(prefsManager.handleSetValueResult)
                }
                firstInit.monitorReady()
            }
        }
        Component.onCompleted: {
            if (hasNativeBackend) {
                var native_src = "./NativeBackend/Monitor.qml"
                var native_props = {
                    interval: main.pollingInterval,
                    running: false,
                    repeat: main.pollingInterval > 0,
                    triggeredOnStart: true,
                }
                monitorLoader.setSource(native_src, native_props);
            } else {
                var local_src = "./DataSourceBackend/Monitor.qml"
                var local_props = {
                    set_prefs: main.set_prefs,
                    pollingInterval: main.pollingInterval
                }
                monitorLoader.setSource(local_src, local_props);
            }
        }
    }

    Item {
        Loader {
            id: updaterLoader
            onLoaded: {
                print("updaterLoader: loaded " + updaterLoader.item.name)
                main.updater = updaterLoader.item
                if (!main.hasNativeBackend) {
                    main.updater.handleSetValueResult
                        .connect(prefsManager.handleSetValueResult)

                    firstInit.scriptReady()
                }
            }
        }
        Component.onCompleted: {
            if (hasNativeBackend) {
                var native_src = "./NativeBackend/Updater.qml"
                var native_props = {
                }
                updaterLoader.setSource(native_src, native_props);
            } else {
                var local_src = "./DataSourceBackend/Updater.qml"
                var local_props = {
                    set_prefs: main.set_prefs,
                }
                updaterLoader.setSource(local_src, local_props);
            }
        }
    }

    Item {
        Loader {
            id: availableValuesLoader
            onLoaded: {
                print("availableValuesLoader: loaded " + availableValuesLoader.item.name)
                availableValuesLoader.item.handleReadAvailResult
                    .connect(prefsManager.handleReadAvailResult)
            }
        }
        Component.onCompleted: {
            if (hasNativeBackend) {
            } else {
                var local_src = "./DataSourceBackend/AvailableValues.qml"
                var local_props = { set_prefs: main.set_prefs, }
                availableValuesLoader.setSource(local_src, local_props);
            }
        }
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
        if (!plasmoid.configuration.monitorWhenHidden) {
            return
        }

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
