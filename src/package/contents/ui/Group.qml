/*
    SPDX-FileCopyrightText: 2018 John Salatas <jsalatas@ictpro.gr>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

import "./" as Pstate


ColumnLayout {
    id: group

    property alias text: group_title.text
    property var items: []
    property var props
    
    objectName: "Group"

    onPropsChanged: {
        text = props['text']
        items = props['items']
        visible = props['visible'] == undefined ||
                  eval('plasmoid.configuration.' + props['visible']) == true
    }

    Component {
        id: slider
        Pstate.Slider {
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            Layout.minimumWidth: units.gridUnit * 1
        }
    }

    Component {
        id: switchbutton
        Pstate.Switch {
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

    Label {
        id: group_title
        font.pointSize: theme.smallestFont.pointSize * 1.25
        color: theme.textColor
        visible: text != ''
    }
}
