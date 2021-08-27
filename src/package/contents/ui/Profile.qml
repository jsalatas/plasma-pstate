import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

import '../code/utils.js' as Utils
import '../code/profile.js' as ProfileUtils

ColumnLayout {
    id: profileView

    /* required */ property var sensors_model

    property alias profileNames: profileComboBox.model
    property alias currentIndex: profileComboBox.currentIndex
    property alias editMode: profileComboBox.editable

    property var editMode: false

    property var originalNames: undefined
    property var originalIndex: -1

    property var hasMessage: false

    // A flattened list of all tunable sensors (view model items)
    property var listModelItems: []

    signal enterEditMode
    signal exitEditMode

    ListModel {
        id: sensorListModel
        dynamicRoles: true
    }

    Connections {
        target: main
        onSensorsValuesChanged: {
            if (!editMode) {
                return
            }

            var profileName = profileNames[currentIndex]

            var profile = mgr.getProfile(profileName)
            for (var i = 0; i < sensorListModel.count; i++) {
                var listItem = sensorListModel.get(i)

                if (listItem.checked) {
                    var sensor = sensors_model[listItem.sensor]
                    profile.sensors[listItem.sensor] = sensor["value"]

                    var valueText = ProfileUtils.getValueText(listItem,
                                                              sensor["value"])
                    sensorListModel.set(i, {"valueText": valueText})
                }
            }
        }
    }

    function applyProfileToSensorsModel(profile, sensorsModel) {
        var keys = Object.keys(profile.sensors)
        for (var i = 0; i < keys.length; i++) {
            var sensor = keys[i]
            var value = profile.sensors[sensor]
            sensorsModel[sensor]['value'] = value
        }
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
            if (sensors_model[item.sensor]["value"] === undefined) {
                return
            }
            sensorListModel.append(item)
        })
    }

    function applyProfileToList(profile) {
        // console.trace()
        var keys = Object.keys(profile.sensors)

        for (var i = 0; i < sensorListModel.count; i++) {
            var listItem = sensorListModel.get(i)

            if (keys.includes(listItem.sensor)) {
                sensorListModel.setProperty(i, "checked", true)
                var value = profile.sensors[listItem.sensor]
                var valueText = ProfileUtils.getValueText(listItem, value)
                sensorListModel.setProperty(i, "valueText", valueText)
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
        var keys = editMode ? undefined : Object.keys(profile.sensors)
        populateList(keys)
        applyProfileToList(profile)

        if (editMode) {
            applyProfileToSensorsModel(profile, sensors_model)
        }
    }

    function listItemClicked(sensor) {
        if (!editMode) {
            return
        }

        var index;
        var listItem;

        // find list item with sensor name
        for (index = sensorListModel.count - 1; index > -1; index--) {
            var listItem = sensorListModel.get(index)
            if (listItem.sensor === sensor) {
                break
            }
        }
        if (index == -1) {
            return
        }

        var isChecked = !listItem.checked
        sensorListModel.setProperty(index, "checked", isChecked)

        var profile = mgr.getProfile(profileNames[currentIndex])

        if (isChecked) {
            var _sensor = sensors_model[sensor]
            if (_sensor["value"] !== undefined) {
                var valueText = ProfileUtils.getValueText(listItem,
                                                          _sensor["value"])
                sensorListModel.setProperty(index, "valueText", valueText)
            }

            profile.sensors[sensor] = _sensor["value"]
        } else {
            delete profile.sensors[sensor]
            sensorListModel.setProperty(index, "valueText", "-")
        }
    }

    function newButtonClicked() {
        var profile = mgr.createProfile()

        var model = profileNames
        model.push(profile.name)
        profileNames = model
        currentIndex = model.length - 1

        showProfile(profile, editMode)
    }

    function editButtonClicked() {
        /* emit */ enterEditMode()

        originalNames = profileNames.slice()
        originalIndex = currentIndex

        if (currentIndex > -1) {
            var profile = mgr.getProfile(profileNames[currentIndex])
            showProfile(profile, true)
        } else {
            sensorListModel.clear()
        }

        editMode = true
    }

    function saveButtonClicked() {
        print("Save " + profileComboBox.editText)

        if (currentIndex > -1) {
            var oldName = profileNames[currentIndex]
            var newName = profileComboBox.editText

            var prevIndex = currentIndex
            if (oldName !== newName) {
                var res = mgr.setProfileName(oldName, newName)
                
                if (res) {
                    var arr = profileNames.slice()

                    // Update the combobox
                    arr[currentIndex] = newName
                    profileNames = arr
                    currentIndex = prevIndex
                } else {
                    showMessage("Invalid profile name.")
                    return
                }
            }
        }

        mgr.saveProfiles()
        plasmoid.nativeInterface.saveProfileList(profileView.profileNames)

        if (currentIndex !== -1) {
            var profile = mgr.getProfile(profileNames[currentIndex])
            showProfile(profile)

            profileComboBox.editText = profile.name
        }

        clearMessage()

        editMode = false
        /* emit */ exitEditMode()
    }

    function deleteButtonClicked() {
        if (!editMode) {
            return
        }
        if (currentIndex === -1) {
            return
        }

        mgr.deleteProfile(profileNames[currentIndex])

        var prevIndex = currentIndex

        var idx = currentIndex
        var model = profileNames
        model.splice(idx, 1)
        profileNames = model
        currentIndex = idx < model.length ? idx : idx - 1

        if (currentIndex > -1) {
            var name = profileNames[currentIndex]
            var profile = mgr.getProfile(name)
            showProfile(profile)
        } else {
            sensorListModel.clear()
        }
    }

    function cancelButtonClicked() {
        if (!editMode) {
            return
        }

        clearMessage()

        if (originalIndex > -1) {
            var name = profileNames[originalIndex]
            var profile = mgr.getProfile(name)
            showProfile(profile, false)
        } else {
            sensorListModel.clear()
        }

        profileNames = originalNames
        currentIndex = originalIndex
        editMode = false

        /* emit */ exitEditMode()
    }

    function applyButtonClicked() {
        var profile = mgr.getProfile(profileNames[currentIndex])

        var keys = Object.keys(profile.sensors)
        for (var i = 0; i < keys.length; i++) {
            var sensor = keys[i]
            var value = profile.sensors[keys[i]]
            /* emit */ updateSensor(sensor, value)
        }
    }

    function comboboxItemClicked(index) {
        if (!editMode) {
            var name = profileNames[currentIndex]
            var profile = mgr.getProfile(name)
            showProfile(profile, editMode)
            applyButtonClicked()
            return
        } else {        
            var name = profileNames[currentIndex]
            var profile = mgr.getProfile(name)
            showProfile(profile, editMode)
        }
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

        showProfile(mgr.getProfile(model[currentIndex]), editMode)
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

        showProfile(mgr.getProfile(model[currentIndex]), editMode)
    }

    function applyProfileName() {
        var oldName = profileNames[currentIndex]
        var newName = profileComboBox.editText
        mgr.setProfileName(oldName, newName)
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

        if (newName == oldName || currentIndex === -1) {
            return
        }

        if (!mgr.validateName(newName)) {
            showMessage("Invalid profile name.")
        } else {
            clearMessage()
        }
    }

    ProfileManager {
        id: mgr

        sensors_model: profileView.sensors_model
        editMode: profileView.editMode

        Component.onCompleted: {
            profileView.enterEditMode.connect(mgr.enterEditMode)
            profileView.exitEditMode.connect(mgr.exitEditMode)

            listModelItems = ProfileUtils.findSensorItems(Utils.get_model())
            sensorListModel.clear()

            profileComboBox.accepted.connect(profileView.applyProfileName)
            profileView.profileNames = mgr.profileNames
            currentIndex = -1
        }
    }

    Component {
        id: sensorItemDelegate

        MouseArea {
            width: profileView.width
            height: childrenRect.height
            enabled: profileView.editMode

            onClicked: listItemClicked(sensor)

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
                        enabled: profileNames && profileNames.length &&
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
    
                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Edit profiles"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: editButtonClicked()
                }
                ToolButton {
                    text: /* New */ "🗎"
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "New profile"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: newButtonClicked()
                }
                ToolButton {
                    text: /* Delete */ "🗑"
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Delete profile"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: deleteButtonClicked()
                }
                ToolButton {
                    text: /* Cancel */ "🗙"
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Layout.alignment: Qt.AlignVCenter | Text.AlignHCenter
                    ToolTip.text: "Discard changes"
                    ToolTip.delay: 250
                    ToolTip.visible: hovered
                    onClicked: cancelButtonClicked()
                }
                ToolButton {
                    text: /* Save */ "🗸"
                    enabled: editMode
                    visible: editMode
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
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
            color: "red"

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
