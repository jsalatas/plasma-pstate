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
