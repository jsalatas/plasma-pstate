import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {
    property alias cfg_useDefaultIcon: useDefaultIconCheckbox.checked
    property alias cfg_showIntelGPU: showIntelGPUCheckbox.checked
    property string cfg_customIcon: plasmoid.configuration.customIcon

    GridLayout {
        Layout.fillWidth: true
        columns: 2

        CheckBox {
            id: useDefaultIconCheckbox
            text: i18n('Use Default Icon')
            Layout.columnSpan: 2
        }

        Label {
            text: i18n("Custom Icon:")
            Layout.alignment: Qt.AlignRight
        }

        IconPicker {
            currentIcon: cfg_customIcon
            onIconChanged: cfg_customIcon = iconName
            onIconCleared: {
                useDefaultIconCheckbox.checked = true
            }
            enabled: !useDefaultIconCheckbox.checked
        }

        CheckBox {
            id: showIntelGPUCheckbox
            text: i18n('Show Intel GPU')
            Layout.columnSpan: 2
        }
    }
}
