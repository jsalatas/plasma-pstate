import QtQuick 2.3

Item {
    id: updater
    property var name: "NativeUpdater"

    function update(parameter, value) {
        var args = [
            "-" + parameter.replace(/_/g, '-'),
            value
        ]

        print("exec: " + args)
        plasmoid.nativeInterface.setPrefs(args)

        if (parameter === 'powermizer') {
            nvidiaPowerMizerDS.update()
        }
    }
}
