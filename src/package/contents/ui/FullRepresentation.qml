/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
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

    Connections {
        target: plasmoid.configuration
        onShowIntelGPUChanged: {
            initialize()
        }
    }

    Connections {
        target: plasmoid.configuration
        onUseSudoForReadingChanged: {
            initialize()
        }
    }

    function initialize() {
        removeChildren()

        for(var i = 0; i < model.length; i++) {
            var item = model[i];
            if(Utils.is_present(item['vendors'])) {
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
