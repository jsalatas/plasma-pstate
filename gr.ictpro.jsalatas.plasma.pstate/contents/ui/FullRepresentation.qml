/*
 *   Copyright 2018 John Salatas <jsalatas@ictpro.gr>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import QtQuick.Layouts 1.1

import '../code/utils.js' as Utils

ColumnLayout {
    id: fullRoot
    spacing: 0.1
    clip: true

    Layout.preferredWidth: childrenRect.width
    Layout.preferredHeight: childrenRect.height

    property var model: Utils.get_model()
    property var vendors: Utils.get_vendors()

    Component {
        id: header
        Header {
        }
    }

    Component.onCompleted: {
        if(isReady) {
            initialize()
            sensorsValuesChanged()
        }
    }

    Connections {
        target: main
        onDataSourceReady: {
            initialize()
            sensorsValuesChanged()
        }
    }

    Connections {
        target: plasmoid.configuration
        onShowIntelGPUChanged: {
            if(isReady) {
                initialize()
            }
        }
    }

    Connections {
        target: plasmoid.configuration
        onUseSudoForReadingChanged: {
            if(isReady) {
                initialize()
            }
        }
    }

    function is_present(item_vendors) {
        if(item_vendors && item_vendors.length != 0) {
            for(var j=0; j< item_vendors.length; j++) {
                var vendor = vendors[item_vendors[j]]
                for(var k=0; k<vendor['provides'].length; k++) {
                    if(sensors_model[vendor['provides'][k]]['value']) {
                        return true;
                        break;
                    }
                }
            }
            return false;
        }

        return true;
    }

    function initialize() {
        removeChildren()

        for(var i = 0; i < model.length; i++) {
            var item = model[i];
            if(is_present(item['vendors'])) {
                switch (item.type) {
                    case 'header': {
                        var obj = header.createObject(fullRoot, {'props': item})
                        break
                    }
                    default: console.log("unkonwn type: " + item.type)
                }
            }
        }
    }
    
    function removeChildren() {
        for(var i = fullRoot.children.length; i > 0 ; i--) {
            fullRoot.children[i-1].destroy()
        }
    }
}
