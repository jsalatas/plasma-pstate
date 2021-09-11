/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.4
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

import '../code/utils.js' as Utils
import '../code/profile.js' as ProfileUtils

import './Model' as Model


ColumnLayout {
    id: profileView

    property alias profileNames: profileComboBox.model
    property alias currentIndex: profileComboBox.currentIndex
    property alias editMode: profileComboBox.editable

    property bool editMode: false

    property int previousIndex: -1

    property var originalNames: undefined
    property int originalIndex: -1

    property bool hasMessage: false

    // A flattened list of all tunable sensors (view model items)
    property var listModelItems: []

    signal enterEditMode
    signal exitEditMode

    ListModel {
        id: sensorListModel
        dynamicRoles: true
    }


    function getCheckedSensors() {
        var checkedSensors = []
        for (var i = 0; i < sensorListModel.count; i++) {
            var listItem = sensorListModel.get(i)
            if (listItem.checked) {
                checkedSensors.push(listItem.sensor)
            }
        }

        return checkedSensors
    }


    /*
     * Populate the list view
     * sensors: Array of sensor names to populate the list.
     *          undefined to populate all items.
     */
    function populateList(sensors) {
        sensorListModel.clear()
        listModelItems.forEach(item => {
            if (sensors && !sensors.includes(item.sensor)) {
                return
            }
            var sensorModel = main.sensorsMgr.getSensor(item.sensor)
            if (sensorModel.value === undefined) {
                return
            }
            sensorListModel.append(item)
        })
    }

    function applyProfile(profile) {
        var keys = profile.getSensorNames()

        for (var i = 0; i < sensorListModel.count; i++) {
            var listItem = sensorListModel.get(i)
            var isChecked = keys.includes(listItem.sensor)

            sensorListModel.setProperty(i, "checked", isChecked)

            if (isChecked) {
                var value = profile.getSensorValue(listItem.sensor)
                var sensorModel = main.sensorsMgr.getSensor(listItem.sensor)

                if (editMode) {
                    sensorModel.value = value
                } else {
                    var valueText = ProfileUtils.getValueText(listItem,
                                                              sensorModel,
                                                              value)
                    sensorListModel.setProperty(i, "valueText", valueText)
                }
            }
        }
    }

    /*
     * Show a sensor profile
     *
     * profile: Profile object
     * editMode: true for edit mode
     */
    function showProfile(profile, editMode) {
        if (!profile) {
            print("showProfile: error: !profile")
            console.trace()
            return
        }

        var keys = editMode ? undefined : profile.getSensorNames()
        populateList(keys)
        applyProfile(profile)
    }

    function onExitEditMode() {
        clearMessage();
    }

    function listItemClicked(sensor) {
        var index;
        var listItem;

        // find list item with sensor name
        for (index = sensorListModel.count - 1; index > -1; index--) {
            listItem = sensorListModel.get(index)
            if (listItem.sensor === sensor) {
                break
            }
        }
        if (index === -1) {
            return
        }

        sensorListModel.setProperty(index, "checked", !listItem.checked)

        var sensorModel = main.sensorsMgr.getSensor(sensor)
        sensorModel.emitValueChanged()
    }

    function newButtonClicked() {
        // Save current shadow profile
        if (currentIndex > -1) {
            mgr.applySensorModelValues(profileComboBox.model[currentIndex],
                                       getCheckedSensors())
        }

        // Create new instance of a profile object
        var profile = mgr.createProfile(profileNames)
        var arr = profileComboBox.model
        arr.push(profile.name)
        profileComboBox.model = arr

        // Show the new profile
        currentIndex = arr.length - 1
        profile = mgr.getProfile(profileComboBox.model[currentIndex])
        showProfile(profile, editMode)

        // Ensure the new shadow profile will be saved
        previousIndex = currentIndex
    }

    function editButtonClicked() {
        if (editMode) {
            return
        }

        originalNames = profileNames.slice()
        originalIndex = currentIndex

        /* emit */ enterEditMode()
        editMode = true

        if (currentIndex > -1) {
            var profile = mgr.getProfile(profileComboBox.model[currentIndex])
            showProfile(profile, editMode)
        }
    }


    function cancelButtonClicked() {
        if (!editMode) {
            return
        }

        /* emit */ exitEditMode()
        editMode = false

        profileNames = originalNames.slice()
        currentIndex = originalIndex
        previousIndex = currentIndex

        if (currentIndex > -1) {
            var profile = mgr.getProfile(profileComboBox.model[currentIndex])
            showProfile(profile, editMode)
        }
    }


    function saveButtonClicked() {
        print("Save " + profileComboBox.editText)
        if (currentIndex > -1) {
            mgr.applySensorModelValues(profileComboBox.model[currentIndex],
                                       getCheckedSensors())
        }

        mgr.commitProfileChanges(profileNames)

        /* emit */ exitEditMode()
        editMode = false

        currentIndex = originalIndex
        previousIndex = currentIndex

        var profile = mgr.getProfile(profileComboBox.model[currentIndex])
        showProfile(profile, false)
    }

    function deleteButtonClicked() {
        if (!editMode) {
            return
        }
        if (currentIndex === -1) {
            return
        }

        mgr.deleteProfile(profileComboBox.model[currentIndex])

        var idx = currentIndex
        var model = profileNames
        model.splice(idx, 1)
        profileNames = model
        currentIndex = idx < model.length ? idx : idx - 1

        if (currentIndex > -1) {
            var name = profileNames[currentIndex]
            var profile = mgr.getProfile(name)
            showProfile(profile, editMode)
        } else {
            sensorListModel.clear()
        }

        previousIndex = currentIndex
    }


    function applyButtonClicked() {
        if (currentIndex === -1) {
            return
        }

        var profile = mgr.getProfile(profileNames[currentIndex])

        var keys = Object.keys(profile.sensors)
        for (var i = 0; i < keys.length; i++) {
            var sensor = keys[i]
            var value = profile.sensors[keys[i]]
            /* emit */ updateSensor(sensor, value)
        }
    }

    function comboboxItemClicked(index) {
        // Save current values to previous profile
        if (editMode && previousIndex > -1) {
            mgr.applySensorModelValues(profileComboBox.model[previousIndex],
                                       getCheckedSensors())
        }

        if (index > -1) {
            var name = profileNames[index]
            var profile = mgr.getProfile(name)
            showProfile(profile, editMode)
        }

        if (!editMode) {
            applyButtonClicked()
        }

        previousIndex = index
    }

    function upButtonClicked() {
        if (currentIndex <= 0) {
            return
        }
        var model = profileNames
        var idx = currentIndex
        var item = model.splice(idx, 1)
        model.splice(idx - 1, 0, item[0])
        profileNames = model
        currentIndex = idx - 1
        previousIndex = currentIndex

        showProfile(mgr.getProfile(profileNames[currentIndex]), editMode)
    }

    function downButtonClicked() {
        if (currentIndex >= profileNames.length - 1) {
            return
        }
        var model = profileNames
        var idx = currentIndex
        var item = model.splice(idx, 1)
        model.splice(idx + 1, 0, item[0])
        profileNames = model
        currentIndex = idx + 1
        previousIndex = currentIndex

        showProfile(mgr.getProfile(profileNames[currentIndex]), editMode)
    }


    function showMessage(message) {
        hasMessage = true
        messageBoxLabel.text = message
    }

    function clearMessage() {
        hasMessage = false
        messageBoxLabel.text = ""
    }

    function profileComboBoxAccepted() {
        if (!editMode) {
            return
        }

        var newName = profileComboBox.editText
        var oldName = profileNames[currentIndex]

        if (newName === oldName || currentIndex === -1) {
            return
        }

        if (!mgr.validateName(newName, profileNames)) {
            showMessage("Invalid profile name.")
        } else {
            clearMessage()

            mgr.renameProfile(oldName, newName)

            // refresh the combobox
            var arr = profileNames
            var idx = currentIndex
            arr[currentIndex] = newName
            profileNames = arr
            currentIndex = idx
        }
    }

    function initialize() {
        profileView.exitEditMode.connect(onExitEditMode)

        profileView.enterEditMode.connect(mgr.enterEditMode)
        profileView.exitEditMode.connect(mgr.exitEditMode)

        mgr.loadProfiles()

        listModelItems = ProfileUtils.findSensorItems(Utils.get_model())
        sensorListModel.clear()

        profileComboBox.accepted.connect(profileView.profileComboBoxAccepted)
        profileView.profileNames = mgr.getProfileNames()
        currentIndex = -1
        previousIndex = currentIndex

        var name = profileNames[0]
        var profile = mgr.getProfile(name)
        showProfile(profile, editMode)
    }


    Model.ProfileManager {
        id: mgr
    }

    Component {
        id: sensorItemDelegate

        MouseArea {
            width: profileView.width
            height: childrenRect.height
            enabled: profileView.editMode

            onClicked: listItemClicked(sensor)

            // save the sensor here so it's accessible in onDestruction
            property var sensorModel

            function onValueChanged(sensorModel) {
                var item = undefined

                if (!editMode) {
                    return
                }

                if (sensorListModel) {
                    for (var i = 0; i < sensorListModel.count; i++) {
                        var listItem = sensorListModel.get(i)
                        if (listItem.sensor === sensorModel.sensor) {
                            item = listItem
                            break;
                        }
                    }
                }

                if (!item || !item.sensor) {
                    print("error: sensorItemDelegate onValueChanged error no " +
                          "item attached")
                    console.trace()
                    return
                }


                if (!item.checked) {
                    valueText = "-"
                    return
                }

                listItem.valueText = ProfileUtils.getValueText(item,
                                                               sensorModel)
            }

            Component.onCompleted: {
                sensorModel = main.sensorsMgr.getSensor(item.sensor)
                sensorModel.onValueChangedCustom.connect(onValueChanged)
            }

            Component.onDestruction: {
                sensorModel.onValueChangedCustom.disconnect(onValueChanged)
                sensorModel = undefined
            }

            ColumnLayout {
                spacing: 0

                Rectangle {
                    /* spacer */
                    width: listView.width
                    height: 1
                    color: Qt.rgba(0,0,0,0)
                }

                Rectangle {
                    width: profileView.width
                    height: childrenRect.height
                    color: !editMode ? Qt.rgba(0,0,0,0.0) :
                           (checked ? theme.highlightColor :
                                      Qt.rgba(0,0,0,0.0))

                    RowLayout {
                        width: profileView.width

                        ColumnLayout {
                            /* sensor group */
                            Label {
                                text: group.text ? group.text : item.text
                                color: !editMode ? theme.disabledTextColor :
                                         checked ? theme.highlightedTextColor :
                                                   theme.textColor


                                font.pointSize: group.text ?
                                                theme.smallestFont.pointSize :
                                                theme.defaultFont.pointSize
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                            /* sensor name */
                            Label {
                                text: group.text ? item.text : ""
                                color: !editMode ? theme.disabledTextColor :
                                         checked ? theme.highlightedTextColor :
                                                   theme.textColor
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }

                        ColumnLayout {

                            Label {
                                text: valueText
                                color: !editMode ? theme.disabledTextColor :
                                         checked ? theme.highlightedTextColor :
                                                   theme.textColor
                                Layout.alignment: Qt.AlignRight
                                horizontalAlignment: Text.AlignRight
                                
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                Rectangle {
                    /* spacer */
                    width: listView.width
                    height: 1
                    color: Qt.rgba(theme.textColor.r,
                                   theme.textColor.g,
                                   theme.textColor.b, 0.6)
                }
            }
        }
    }

    // Sensor header
    Component {
        id: sectionHeading
        Rectangle {
            width: profileView.width
            height: childrenRect.height
            color: theme.headerBackgroundColor ? theme.headerBackgroundColor :
                                                 theme.backgroundColor

            RowLayout {
                width: profileView.width

                Label {
                    text: section
                    color: theme.headerTextColor ? theme.headerTextColor :
                                                   theme.textColor
                    font.bold: true
                    font.pixelSize: units.defaultFont * 2.0
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    ColumnLayout {
        spacing: 0
        ColumnLayout {
            RowLayout {
                ComboBox {
                    id: profileComboBox
                    // model: profileNames /* aliased to root object */
                    // editable: /* aliased to root object */
                    Layout.fillWidth: true

                    onActivated: comboboxItemClicked(index)
                    onAccepted: profileComboBoxAccepted()
                    onEditTextChanged: profileComboBoxAccepted()

                    contentItem: TextField {
                        id: textField

                        padding: 0
                        Layout.leftMargin: 0
                        Layout.rightMargin: profileComboBox.indicator.width * 2

                        focus:  profileComboBox.editable
                        visible: profileComboBox.editable
                        enabled: profileComboBox.editable

                        text: profileComboBox.editable ?
                                profileComboBox.editText :
                                profileComboBox.displayText
                    }
                }

                ColumnLayout {
                    spacing: 0

                    ToolButton {
                        text: /* Up */ "▲"
                        visible: editMode
                        enabled: profileNames !== undefined && currentIndex > 0
                        contentItem: Text {
                            text: parent.text
                            font.pointSize: theme.smallestFont.pointSize
                            color: enabled ? theme.textColor : theme.disabledTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                                                        }
                        Layout.preferredWidth: units.largeSpacing
                        Layout.preferredHeight: units.largeSpacing

                        Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                        ToolTip.text: "Move profile up"
                        ToolTip.delay: 250
                        ToolTip.visible: hovered
                        onClicked: upButtonClicked()
                    }
                    ToolButton {
                        text: /* Down */ "▼"
                        visible: editMode
                        enabled: profileNames !== undefined && profileNames.length &&
                                    -1 < currentIndex && currentIndex < profileNames.length - 1
                        contentItem: Text {
                            text: parent.text
                            font.pointSize: theme.smallestFont.pointSize
                            color: enabled ? theme.textColor : theme.disabledTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Layout.preferredWidth: units.largeSpacing
                        Layout.preferredHeight: units.largeSpacing
                        Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                        ToolTip.text: "Move profile down"
                        ToolTip.delay: 250
                        ToolTip.visible: hovered
                        onClicked: downButtonClicked()
                    }
                }

                ToolButton {
                    id: editButton
                    text: /* Edit */ "🖉"
                    visible: !editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextMetrics {
                        id: textMetrics
                        font: editButton.contentItem.font
                        text: editButton.text
                    }
                    Component.onCompleted: {
                        // Binding the property causes a segfault on exit.
                        // Workaround by assigning the value here.
                        Layout.maximumWidth = (2 * textMetrics.width) +
                                              (2 * units.smallSpacing)
                    }
                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Edit profiles"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: editButtonClicked()
                }

                ToolButton {
                    id: newButton
                    text: /* New */ "🗎"
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextMetrics {
                        id: newTextMetrics
                        font: newButton.contentItem.font
                        text: newButton.text
                    }
                    Component.onCompleted: {
                        Layout.maximumWidth = (2 * newTextMetrics.width) +
                                              (2 * units.smallSpacing)
                    }
                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "New profile"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: newButtonClicked()
                }
                ToolButton {
                    id: delButton
                    text: /* Delete */ "🗑"
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextMetrics {
                        id: delTextMetrics
                        font: delButton.contentItem.font
                        text: delButton.text
                    }
                    Component.onCompleted: {
                        Layout.maximumWidth = (2 * delTextMetrics.width) +
                                              (2 * units.smallSpacing)
                    }
                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Delete profile"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: deleteButtonClicked()
                }
                ToolButton {
                    id: cancelButton
                    text: /* Cancel */ "🗙"
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextMetrics {
                        id: cancelTextMetrics
                        font: cancelButton.contentItem.font
                        text: cancelButton.text
                    }
                    Component.onCompleted: {
                        Layout.maximumWidth = (2 * cancelTextMetrics.width) +
                                              (2 * units.smallSpacing)
                    }
                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Discard changes"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: cancelButtonClicked()
                }
                ToolButton {
                    id: saveButton
                    text: /* Save */ "🗸"
                    enabled: editMode
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextMetrics {
                        id: saveTextMetrics
                        font: saveButton.contentItem.font
                        text: saveButton.text
                    }
                    Component.onCompleted: {
                        Layout.maximumWidth = (2 * saveTextMetrics.width) +
                                              (2 * units.smallSpacing)
                    }
                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Save changes"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered

                    onClicked: saveButtonClicked()

                }
            }
        }

        Rectangle {
            id: messageBox
            Layout.preferredWidth: profileView.width
            Layout.preferredHeight: childrenRect.height
            visible: hasMessage
            color: theme.negativeTextColor ? theme.negativeTextColor : "red"

            Label {
                id: messageBoxLabel
                text: ""
                color: "white"
                Layout.fillWidth: true
            }
        }

        ListView {
            id: listView
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true

            delegate: sensorItemDelegate
            model: sensorListModel

            section.property: "headerText"
            section.criteria: ViewSection.FullString
            section.delegate: sectionHeading
        }
    }
}
