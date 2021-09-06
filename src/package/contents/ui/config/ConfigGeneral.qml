import QtQuick 2.2
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

import org.kde.kirigami 2.3 as Kirigami

ColumnLayout {
    property alias cfg_useDefaultIcon: useDefaultIconCheckbox.checked
    property alias cfg_showIntelGPU: showIntelGPUCheckbox.checked
    property string cfg_customIcon: plasmoid.configuration.customIcon
    property alias cfg_useSudoForReading: useSudoForReadingCheckbox.checked
    property alias cfg_pollingInterval: pollingInterval.value
    property alias cfg_monitorWhenHidden: monitorWhenHidden.checked
    property alias cfg_slowPollingInterval: slowPollingInterval.value
    property bool cfg_hasNativeBackend: false

    Kirigami.FormLayout {
        Layout.fillHeight: true

        CheckBox {
            id: useDefaultIconCheckbox
            Kirigami.FormData.label: i18n('Use Default Icon')
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
            Kirigami.FormData.label: i18n('Show Intel GPU')
        }

        CheckBox {
            id: useSudoForReadingCheckbox
            Kirigami.FormData.label: i18n('Use sudo for reading values')
            visible: !cfg_hasNativeBackend
        }

        SpinBox {
            id: pollingInterval

            Kirigami.FormData.label: i18n("Polling Interval (seconds):")

            from: 2
            to: 3600
        }

        CheckBox {
            id: monitorWhenHidden
            Kirigami.FormData.label: i18n('Show sensors in tool tip')
        }

        SpinBox {
            id: slowPollingInterval

            Kirigami.FormData.label: i18n("Tool Tip polling interval (seconds):")

            from: 2
            to: 3600
            enabled: monitorWhenHidden.checked
        }
    }
}
