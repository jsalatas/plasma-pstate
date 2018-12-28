import QtQuick 2.2
import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.Label {
    anchors.fill: parent
    
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    font.pixelSize: Math.min(parent.height, parent.width) * (inTray ? 1: 0.7)
    font.pointSize: -1
    font.family: symbolsFont.name
    
    text: 'd'
    
     MouseArea {
        id: mousearea
        anchors.fill: parent
        onClicked: {
            if(main.isInitialized) {
                // FIXME: There is an initial time that thw widget's button doesn't respond to clicks
                plasmoid.expanded = !plasmoid.expanded 
            }
        }
     }
}
