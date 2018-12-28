import QtQuick 2.3
import QtQuick.Layouts 1.1
import org.kde.plasma.components 2.0 as PlasmaComponents

ColumnLayout {
    id: radio
    height: radio_title.height + buttons.height
    
    property alias text: radio_title.text
    property var sensor: []
    property var items: []

    property var props

    objectName: "Radio"

    Component {
        id: pushButton
        PushButton {}
    }

    onPropsChanged: {
        text = props['text']
        sensor.push(props['sensor'])
        items = props['items']
    }
    
    onItemsChanged: {
        for(var i = 0; i < items.length; i++) {
            var props = items[i]
            props['sensor'] = sensor
            pushButton.createObject(buttons, props);
        }
    }

    PlasmaComponents.Label {
        id: radio_title
        font.pointSize: theme.smallestFont.pointSize * 1.25
        color: theme.textColor
        visible: text != ''
    }
    RowLayout {
        id: buttons
        spacing: -0.5
        Layout.topMargin: radio_title.visible ? 0 : 8

        height: units.gridUnit * 4
    }
}
