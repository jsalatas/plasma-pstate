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

import './Model' as Model

Item {
    id: main
    
    signal dataSourceReady
    signal updateSensor(string name, string value)

    FontLoader {
        id: symbolsFont;
        source: '../font/plasma-pstate.ttf'
    }

    property var tabbedRep: undefined

    property var monitor_sources: [
        /cpu\/system\/AverageClock/g,
        /cpu\/system\/TotalLoad/g,
        /lmsensors\/.*Package_id_0/g,
        /lmsensors\/.*fan/g
    ]

    property var updater: undefined
    property var monitorDS: undefined

    property bool isInitialized: false
    property bool inTray: false

    property bool editMode: false

    property bool hasNativeBackend: plasmoid.nativeInterface.isReady !== undefined

    readonly property string set_prefs: '/usr/share/plasma/plasmoids/' +
                                        'gr.ictpro.jsalatas.plasma.pstate/contents/code/' +
                                        'set_prefs.sh'

    property int pollingInterval: plasmoid.configuration.pollingInterval ?
                                  (plasmoid.configuration.pollingInterval * 1000) : 2000
    property int slowPollingInterval: (plasmoid.configuration.slowPollingInterval * 1000)

    function sensor_short_name(long_name) {
        var parts = long_name.split('/');
        return parts[parts.length - 1];
    }

    Plasmoid.compactRepresentation: CompactRepresentation { }
    // Plasmoid.fullRepresentation: FullRepresentation { }

    Plasmoid.fullRepresentation: TabbedRepresentation {
        id: tabbedRep
        Component.onCompleted: {
            firstInit.viewReady()
            main.tabbedRep = tabbedRep
        }
    }


    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.switchWidth: units.gridUnit * 15
    Plasmoid.switchHeight: units.gridUnit * 20

    property var toolTipMainText
    property var toolTipSubText
    property var toolTipTextFormat
    property var icon

    property var sensorsMgr


    Component {
        id: sensorsMgrComponent
        Model.SensorsManager {
        }
    }

    FirstInit {
        id: firstInit
        Component.onCompleted: {
            sensorsMgr = sensorsMgrComponent.createObject()
            firstInit.beginStageOne.connect(onBeginStageOne)
            firstInit.beginStageTwo.connect(onBeginStageTwo)
            firstInit.initialized.connect(main.initialized)
            /* emit */ firstInit.beginStageOne()
        }

        function onBeginStageOne() {
            sensorsMgr.loadSensors()
            if (main.hasNativeBackend) {
                nativeBackendInit.init(firstInit.scriptReady)
            }
        }

        function onBeginStageTwo() {
            if (main.hasNativeBackend) {
                firstInit.initialized.connect(monitorDS.dataSourceReady)
                main.monitorDS.init()
            }
        }
    }

    NativeBackend.Init {
        id: nativeBackendInit
        hasNativeBackend: main.hasNativeBackend
    }

    Component.onCompleted: {
        inTray = plasmoid.parent != null &&
                 ((plasmoid.parent.pluginName ===
                    'org.kde.plasma.private.systemtray') ||
                  (plasmoid.parent.objectName === 'taskItemContainer'))
    }

    function initialized() {
        plasmoid.configuration.hasNativeBackend = hasNativeBackend

        main.updateSensor.connect(prefsManager.updateSensor)
        prefsManager.update.connect(updater.update)

        toolTipMainText = plasmoid.toolTipMainText
        toolTipSubText = plasmoid.toolTipSubText
        toolTipTextFormat = plasmoid.toolTipTextFormat
        icon = plasmoid.icon

        if (plasmoid.configuration.monitorWhenHidden) {
            useCustomToolTip()
        }

        if (plasmoid.expanded) {
            setMonitorInterval(pollingInterval)
        } else {
            setMonitorInterval(slowPollingInterval)
        }

        isInitialized = true


        if (shouldMonitor()) {
            startMonitors()
        } else {
            stopMonitors()
        }

        main.tabbedRep.initialize()
        main.tabbedRep.show_item("processorSettings")
    }

    function enterEditMode() {
        stopMonitors()
        editMode = true
        main.updateSensor.disconnect(prefsManager.updateSensor)
        main.updateSensor.connect(main.phonyUpdateSensor)
    }

    function exitEditMode() {
        main.updateSensor.disconnect(main.phonyUpdateSensor)
        main.updateSensor.connect(prefsManager.updateSensor)
        editMode = false
        startMonitors()
    }

    function phonyUpdateSensor(name, value) {
        sensorsMgr.setSensorValue(name, value)
    }


    function shouldMonitor() {
        if (editMode) {
            return false
        }
        return !inTray || plasmoid.expanded ||
                plasmoid.configuration.monitorWhenHidden
    }

    function startMonitors() {
        if (!plasmoid.expanded) {
            connectTooltipSensors()
        }
        powermanagementDS.start()
        systemmonitorDS.start()
        monitorDS.start()
    }

    function stopMonitors() {
        powermanagementDS.stop()
        systemmonitorDS.stop()
        monitorDS.stop()

        if (!plasmoid.expanded) {
            disconnectTooltipSensors()
        }
    }

    function setMonitorInterval(interval) {
        powermanagementDS.interval = interval
        systemmonitorDS.interval = interval
        monitorDS.interval = interval
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

    function monitor_source(src) {
        for(var i=0; i < monitor_sources.length; i++) {
            if(src.match(monitor_sources[i])) {
                return true;
            }
        }

        return false;
    }

    PlasmaCore.DataSource {
        id: systemmonitorDS
        engine: 'systemmonitor'

        property var sources: []

        onSourceAdded: {
             if(monitor_source(source)) {
                 if(connectedSources.indexOf(source) === -1) {
                    connectSource(source);
                    sources.push(source)
                 }
            }
        }

        onNewData: {
            var source_short_name = sensor_short_name(sourceName);

            if(source_short_name.startsWith('fan')) {
                var sensorModel = sensorsMgr.getSensor('fan_speeds')
                if (sensorModel.value !== undefined) {
                    var arr = sensorModel.value
                    arr[source_short_name] = data.value
                    sensorModel.value = arr
                }
            } else {
                switch (source_short_name) {
                    case 'AverageClock': {
                        sensorsMgr.setSensorValue('cpu_cur_freq', data.value)
                        break;
                    }
                    case 'Package_id_0': {
                        sensorsMgr.setSensorValue('package_temp', data.value)
                        break;
                    }
                    case 'TotalLoad': {
                        sensorsMgr.setSensorValue('cpu_cur_load', data.value)
                        break;
                    }
                }
            }
        }
        interval: pollingInterval

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
                var sensorModel = undefined

                var bat_time = Number(powermanagementDS.data["Battery"]["Remaining msec"]) / 1000;
                sensorsMgr.setSensorValue('battery_remaining_time', bat_time)

                var bat_charge = powermanagementDS.data["Battery"]["Percent"];
                sensorsMgr.setSensorValue('battery_percentage', bat_charge)
            }
        }
        interval: pollingInterval

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
            if (!main.isInitialized) {
                return
            }

            stopMonitors()

            if (plasmoid.expanded) {
                setMonitorInterval(pollingInterval)
            } else {
                setMonitorInterval(slowPollingInterval)
            }

            if (shouldMonitor()) {
                startMonitors()
            }
        }
    }

    Connections {
        target: plasmoid.configuration
        onUseSudoForReadingChanged: {
            if (shouldMonitor()) {
                stopMonitors
                startMonitors()
            }
        }

        onPollingIntervalChanged: {
            pollingInterval = plasmoid.configuration.pollingInterval * 1000

            stopMonitors()
            setMonitorInterval(pollingInterval)

            if (shouldMonitor()) {
                startMonitors()
            }
        }

        onSlowPollingIntervalChanged: {
            slowPollingInterval = plasmoid.configuration.slowPollingInterval * 1000

            stopMonitors()
            setMonitorInterval(slowPollingInterval)

            if (shouldMonitor()) {
                startMonitors()
            }
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

        Component.onCompleted: {
            prefsManager.setPrefsReady.connect(firstInit.dataReady)
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
        Component.onCompleted: {
            nvidiaPowerMizerDS.dataSourceReady.connect(tabbedRep.initialize)
        }
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


    // One sensor from each monitor is enough
    property var tooltipSensors: ['cpu_cur_load', 'gpu_cur_freq', 'battery_percentage' ]

    function connectTooltipSensors() {
        for (var i in tooltipSensors) {
            var sensor = tooltipSensors[i]
            var sensorModel = sensorsMgr.getSensor(sensor)
            sensorModel.onValueChanged.connect(updateTooltip)
        }
    }

    function disconnectTooltipSensors() {
        for (var i in tooltipSensors) {
            var sensor = tooltipSensors[i]
            var sensorModel = sensorsMgr.getSensor(sensor)
            sensorModel.onValueChanged.disconnect(updateTooltip)
        }
    }

    function updateTooltip() {
        if (!plasmoid.configuration.monitorWhenHidden) {
            return
        }

        var loadText = Utils.get_sensors_text(['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'])

        var toolTipSubText ='';
        var txt = '';

        toolTipSubText += '<font size="4"><table>'

        toolTipSubText += '<tr>'
        toolTipSubText += '<td style="text-align: right;">'
        toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">d</font></span>'
        toolTipSubText += '</td>'
        toolTipSubText += '<td style="text-align: left;">'
        toolTipSubText += '<span>&nbsp;&nbsp;' + loadText +'</span>'
        toolTipSubText += '</td>'
        toolTipSubText += '</tr>'

        txt = Utils.get_sensors_text(['battery_percentage', 'battery_remaining_time']);
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

        txt = Utils.get_sensors_text(['package_temp', 'fan_speeds']);
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
