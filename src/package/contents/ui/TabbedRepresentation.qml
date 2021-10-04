/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.3
import QtQuick.Controls 2.2

import QtQuick.Layouts 1.1
import QtQuick.Window 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

import '../code/utils.js' as Utils

GridLayout {
    id: tabbedRepresentation

    Layout.minimumWidth: units.gridUnit * 24
    Layout.minimumHeight: units.gridUnit * 24
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    property var model: Utils.get_model()
    property var vendors: Utils.get_vendors()

    property var currentItemId: undefined

    property var profileView: undefined
    property bool editMode: false


    Component {
        id: header
        Header {
        }
    }

    Component {
        id: toolButton
        ToolButton {
            id: button
            text: undefined
            ToolTip.visible: hovered
            property var symbolText
            property var itemId
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            contentItem: Text {
                    id: buttonText
                    text: button.symbolText
                    font.family: symbolsFont.name
                    font.pointSize: theme.smallestFont.pointSize * 2.5
                    color: editMode ? theme.backgroundColor : theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
            }
            background: Rectangle {
                color: Qt.rgba(0, 0, 0, 0)
                radius: 2
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    buttonText.color = editMode ? theme.highlightColor :
                                                  theme.highlightColor
                }
                onExited: {
                    buttonText.color = editMode ? theme.backgroundColor :
                                                  theme.textColor
                }
                onClicked: {
                    show_item(itemId)
                }
            }

            Connections {
                target: tabbedRepresentation
                onEditModeChanged: {
                    buttonText.color = editMode ? theme.backgroundColor :
                                                  theme.textColor
                }
            }

            onActiveFocusChanged: {
                if (activeFocus) {
                    buttonText.color = theme.highlightColor
                } else {
                    buttonText.color = theme.textColor
                }
            }
        }
    }

    Component {
        id: scrollComponent
        ScrollView {
            id: scrollRoot
            property alias props: scrolledHeader.props
            property alias showIcon: scrolledHeader.showIcon

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.interactive: false

            Header {
                id: scrolledHeader
                width: scrollRoot.width
            }
        }
    }

    Component {
        id: profileComponent
        Profile {
            id: profileView

        }
    }

    property bool isInitialized: false

    Connections {
        target: plasmoid.configuration
        onShowIntelGPUChanged: {
            initialize()
        }
    }

    function initialize() {
        remove_children()
        initialize_toolbar()

        if (isInitialized) {
            return
        }

        if (main.hasNativeBackend) {
            profileView.initialize()
        }

        isInitialized = true
    }

    function initialize_toolbar() {
        for(var i = 0; i < model.length; i++) {
            var item = model[i];
            // if(!Utils.is_present(item['vendors'])) {
            if(!Utils.sensor_has_value(item)) {
                continue
            }
            switch (item.type) {
                case 'header': {
                    var props = { symbolText: item['icon'], itemId: item['id'] }
                    var obj = toolButton.createObject(toolbar, props)
                    obj.ToolTip.text = item.text
                    obj.ToolTip.delay = 1000
                    break
                }
                default: console.log("unkonwn type: " + item.type)
            }
        }
    }

    function remove_children() {
        for(var i = toolbar.children.length; i > 0 ; i--) {
            toolbar.children[i-1].destroy()
        }
    }

    function set_indicator_position(itemId) {
        var item = undefined
        for(var i = toolbar.children.length; i > 0 ; i--) {
            var button = toolbar.children[i-1];
            if (button.itemId !== itemId) {
                continue
            }

            item = button
            break
        }

        if (!item && itemId === "profilePage") {
            item = profileButton
        }

        if (item) {
            var res = item.mapToItem(toolbar, 0, 0)
            toolbarIndicator.y = res.y
            toolbarIndicator.height = button.height
        }
    }

    function onEnterEditMode() {
        editMode = true
    }

    function onExitEditMode() {
        editMode = false
    }

    function show_item(itemId) {
        if (itemId === "profilePage") {
            if (currentItemId !== itemId) {
                stackView.clear(StackView.PopTransition)
                stackView.push(profileView, StackView.PushTransition)
                currentItemId = itemId
            }
            set_indicator_position(currentItemId)

            return
        }

        var item = undefined
        model.forEach(m => {
            if (!item && m['id'] === itemId) {
                item = m
            }
        })
        if (!item) {
            print("error: Couldn't find item with id=" + itemId)
            return
        }


        var props = {'props': item, showIcon: false};
        if (currentItemId && currentItemId === itemId) {
            // clicking on the same item reloads it
            stackView.pop(StackView.Immediate)
            stackView.push(scrollComponent, props, StackView.Immediate)
        }

        stackView.clear(StackView.PopTransition)
        stackView.push(scrollComponent, props, StackView.PushTransition)
        tabbedRepresentation.currentItemId = itemId
        set_indicator_position(currentItemId)
    }

    Component.onCompleted: {
        profileView = profileComponent.createObject()

        profileView.enterEditMode.connect(onEnterEditMode)
        profileView.exitEditMode.connect(onExitEditMode)

        profileView.enterEditMode.connect(main.enterEditMode)
        profileView.exitEditMode.connect(main.exitEditMode)
    }


    RowLayout {
        spacing: 0

        // Tab bar
        Rectangle {
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: tabbedRepresentation.height

            color: editMode ? theme.textColor : Qt.rgba(0,0,0,0)

            ColumnLayout {
                height: tabbedRepresentation.height

                ColumnLayout {
                    id: toolbar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Item {
                    /* spacer */
                    Layout.fillHeight: true
                }

                Loader {
                    id: profileButton
                    visible: main.hasNativeBackend
                    sourceComponent: toolButton
                    onLoaded: {
                        item.symbolText = /* Black Star */ "\u2605"
                        item.itemId = "profilePage"
                        item.ToolTip.text = "Profiles"
                        item.ToolTip.delay = 1000
                    }
                }
            }
        }

        Rectangle {
            id: toolbarIndicator
            x: toolbar.width
            height: toolbar.height
            // This makes the plasmoid crash on removal.
            // width: toolbar.width * 0.075
            width: units.smallSpacing.toFixed(3) * 0.5
            color: theme.highlightColor

            Behavior on y { PropertyAnimation {} }
        }

        // Vertical separator
        GridLayout {
            Rectangle {
                id: separator
                width: 1
                color: Qt.rgba(theme.textColor.r,
                               theme.textColor.g,
                               theme.textColor.b, 0.25)
                Layout.fillHeight: true
            }
        }

        RowLayout {
            spacing: 0
            clip: true

            // spacer
            Rectangle {
                width: units.smallSpacing
                color: Qt.rgba(1, 1, 1, 0)
                Layout.fillHeight: true
            }

            StackView {
                id: stackView

                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

}
