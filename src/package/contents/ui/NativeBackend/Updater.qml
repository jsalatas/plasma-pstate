import QtQuick 2.3

Item {
    id: updater
    property var name: "NativeUpdater"

    function update(sensor, args) {
        var _args = ["-write-sensor", sensor]
        _args = _args.concat(args)

        print("exec: " + _args)
        plasmoid.nativeInterface.setPrefs(_args)

        if (sensor === 'powermizer') {
            nvidiaPowerMizerDS.update()
        }
    }
}
