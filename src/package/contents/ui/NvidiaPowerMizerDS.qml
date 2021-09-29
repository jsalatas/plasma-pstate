import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: nvidiaPowerMizer

    PlasmaCore.DataSource {
        id: datasource
        engine: 'executable'
        interval: 0

        property var previous_value: undefined

        property var hasNvGpu: undefined
        readonly property int maxIter: 5
        property int iterations: 0

        property string commandCheck: "grep -H 0x10de /sys/class/drm/card?/device/vendor 2>/dev/null"

        property string commandSource: "nvidia-settings -q GpuPowerMizerMode | " +
                                       "grep \"Attribute 'GPUPowerMizerMode'\" | " +
                                       "awk -F \"): \" '{print $2}' | awk -F \".\" '{print $1}'"

       signal dataSourceReady()

        onNewData: {
            if (sourceName === commandCheck) {
                check_hardware(sourceName, data)
            } else {
                check_powermizer(sourceName, data)
            }
        }

        function check_hardware(sourceName, data) {
            disconnectSource(commandCheck)

            hasNvGpu = data.stdout.length !== 0
            if (hasNvGpu) {
                print("NvidiaPowerMizerDS: Checking powermizer status.")
                connectSource(commandSource);
            } else {
                print("NvidiaPowerMizerDS: No Nvidia GPU found.")
            }
        }

        function check_powermizer(sourceName, data) {
            iterations = iterations + 1

            if (data['exit code'] !== 0 || data.stderr.length > 0) {
                print('NvidiaPowerMizerDS error: ' + data.stderr)
                return
            }

            var val = parseInt(data.stdout)

            if (previous_value !== val || iterations >= maxIter) {
                disconnectSource(sourceName)

                if (iterations >= maxIter) {
                    var t = (interval * maxIter) / 1000
                    print("NvidiaPowerMizerDS: powermizer value did not change after " + t +
                          " seconds")
                }

                var sensorModel = main.sensorsMgr.getSensor("powermizer")
                sensorModel.value = val

                if (previous_value === undefined) {
                    /* emit */ dataSourceReady()
                }

                previous_value = val
            }
        }

        function has_nvgpu() {
            return hasNvGpu
        }

        function start() {
            connectSource(commandCheck);
        }

        function update() {
            print("NvidiaPowerMizerDS: Updating status.")
            iterations = 0
            interval = 1000
            connectSource(commandSource)
        }
    }

    Component.onCompleted: {
        print("NvidiaPowerMizerDS: Checking for Nvidia GPU.")
        datasource.start()
    }

    function update() {
        if (!datasource.has_nvgpu()) {
            print("NvidiaPowerMizerDS: No Nvidia GPU detected.")
            return;
        }

        datasource.update()
    }
}
