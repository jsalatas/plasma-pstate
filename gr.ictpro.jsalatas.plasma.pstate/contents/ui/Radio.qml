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
        Layout.rightMargin: 15

        height: units.gridUnit * 4
    }
}
