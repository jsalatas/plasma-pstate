/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.0

import '../../code/profile.js' as ProfileUtils


QtObject {
    objectName: "Profile"
    id: profileObject

    property var name: undefined

    /*
     * Data format:
     *  { sensor1: value, sensor2: value, ... }
     */
    property var sensors: {}

    function copy(profile) {
        profileObject.name = profile.name
        profileObject.sensors = ProfileUtils.deepCopy(profile.sensors)
        return profileObject
    }

    function loadProfile(name, data) {
        profileObject.name = name
        profileObject.sensors = JSON.parse(data)
    }

    function getSensorNames() {
        return Object.keys(sensors)
    }

    function getSensorValue(name) {
        return sensors[name]
    }
}
