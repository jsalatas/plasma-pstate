import QtQuick 2.5
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.1

import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.kirigami 2.3 as Kirigami


// basically taken from kickoff
Button {
    id: iconButton

    Kirigami.FormData.label: i18n("Icon:")

    property string currentIcon
    property string defaultIcon

    signal iconChanged(string iconName)
    signal iconCleared

    Layout.minimumWidth: previewFrame.width
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: previewFrame.height
    Layout.maximumHeight: Layout.minimumHeight

    background: Rectangle {
        color: Qt.rgba(0,0,0,0)
        width: previewFrame.width
        height: previewFrame.height

        MouseArea {
            anchors.fill: parent
            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()
        }
    }

    KQuickAddons.IconDialog {
        id: iconDialog
        onIconNameChanged: {
            iconPreview.source = iconName
            iconChanged(iconName)
        }
    }

    PlasmaCore.FrameSvgItem {
        id: previewFrame
        imagePath: plasmoid.location === PlasmaCore.Types.Vertical ||
                   plasmoid.location === PlasmaCore.Types.Horizontal ?
                   "widgets/panel-background" : "widgets/background"
        width: units.iconSizes.large + fixedMargins.left + fixedMargins.right
        height: units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

        PlasmaCore.IconItem {
            id: iconPreview
            anchors.centerIn: parent
            width: units.iconSizes.large
            height: width
            source: currentIcon
        }
    }

    function setDefaultIcon() {
        iconPreview.source = defaultIcon
        iconChanged(defaultIcon)
        iconCleared()
    }

    Menu {
        id: iconMenu

        // Appear below the button
        y: +parent.height

        MenuItem {
            text: i18nc("@item:inmenu Open icon chooser dialog", "Choose...")
            icon.name: "document-open-folder"
            onPressed: iconDialog.open()
        }
        MenuItem {
            text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
            icon.name: "edit-clear"
            onPressed: setDefaultIcon()
        }
    }
}
