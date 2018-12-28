import QtQuick 2.3
import QtQuick.Layouts 1.1
import org.kde.plasma.components 2.0 as PlasmaComponents

ColumnLayout {
    id: group
    
    property alias text: group_title.text
    property var items: []

    property var props

    objectName: "Group"

    onPropsChanged: {
        text = props['text']
        items = props['items']
    }
    
    Component {
        id: slider
        Slider {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            Layout.minimumWidth: units.gridUnit * 18
        }
    }
    
    Component {
        id: switchbutton
        Switch {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }
    }

    onItemsChanged: {
        for(var i = 0; i < items.length; i++) {
            switch (items[i]['type']) {
                case 'slider': {
                    slider.createObject(group, {'props': items[i]})
                    break
                }
                case 'switch': {
                    switchbutton.createObject(group, {'props': items[i]})
                    break
                }
                default: console.log("header: unkonwn type: " + items[i]['type'])

            }

        }
    }

    PlasmaComponents.Label {
        id: group_title
        font.pointSize: theme.smallestFont.pointSize * 1.25
        color: theme.textColor
        visible: text != ''
    }
    
}
