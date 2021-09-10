import QtQuick 2.3

Item {
    id: updater
    property var name: "NativeUpdater"

    function update(parameter, args) {
        var _args = ["-" + parameter.replace(/_/g, '-')]
        _args = _args.concat(args)

        print("exec: " + _args)
        plasmoid.nativeInterface.setPrefs(_args)

        if (parameter === 'powermizer') {
            nvidiaPowerMizerDS.update()
        }
    }
}
