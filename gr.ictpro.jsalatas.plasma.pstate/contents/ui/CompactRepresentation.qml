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
            plasmoid.expanded = !plasmoid.expanded
        }
    }
}
