import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.components 2.0 as PlasmaComponents

Row {
    id: header

    topPadding: 5
    bottomPadding: 10
    
    property alias symbol: icon.text
    property alias text: title.text
    property var sensors: []
    property var items: []
    
    property var props

    Component {
        id: group
        Group {
            Layout.topMargin: 5
            Layout.bottomMargin: 10
        }
    }
    
    Component {
        id: radio
        Radio {
            Layout.topMargin: 5
            Layout.bottomMargin: 10
        }
    }

    Connections {
        target: main
        onSensorsValuesChanged: {
            sensors_label.text = get_sensors_text(sensors);
        }
    }
    
    onItemsChanged: {
        // parent: controls
        for(var i = 0; i < items.length; i++) {
            switch (items[i]['type']) {
                case 'radio': {
                    radio.createObject(controls, {'props': items[i]})
                    break
                }
                case 'group': {
                    group.createObject(controls, {'props': items[i]})
                    break
                }
                default: console.log("header: unkonwn type: " + items[i]['type'])

            }
        }
        
    }

    onPropsChanged: {
        symbol = props['icon']
        text = props['text']
        sensors = props['sensors']
        items = props['items']
    }

    GridLayout {
        id: grid
        
        columns: 2
        columnSpacing: 10
        rowSpacing: 0
        
        PlasmaComponents.Label {
            id: icon
            
            width: units.gridUnit * 2.2
            Layout.minimumWidth : width
            
            horizontalAlignment: Text.AlignHCenter
            
            font.pointSize: theme.smallestFont.pointSize * 2.5
            font.family: symbolsFont.name
            color: theme.textColor
        }

        PlasmaComponents.Label {
            id: title

            font.pointSize: theme.smallestFont.pointSize * 2
            color: theme.textColor
        }

        PlasmaComponents.Label  {
            id: spacer0
            visible: sensors_label.text != 'N/A'
        }
        PlasmaComponents.Label {
            id: sensors_label
  
            //Layout.columnSpan: 2
            Layout.bottomMargin: 5
  
            font.pointSize: theme.smallestFont.pointSize * 1.25
            color: theme.textColor
            opacity: 0.8
            
            //FIXME: This is a bug. Should be empty text instead of 'N/A'. 
            // However, if initially is empty it cannot calculate the height or something
            visible: sensors_label.text != 'N/A'
            
        }
        
        PlasmaComponents.Label  {
            id: spacer1
        }
        ColumnLayout {
            id: controls
  
            //Layout.columnSpan: 2
            //Layout.leftMargin: grid.columnSpacing + icon.width
        }

    }
}
