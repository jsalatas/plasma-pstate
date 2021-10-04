/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.0


QtObject {
    objectName: "ProfileManager"
    id: profileMgr

    property var profileComponent: undefined

    property var profilesMap: ({})

    property var sensorsModelBackup: ({})
    property var shadowProfilesMap: ({})
    property var deletedProfiles: []

    property bool editMode: false


    function loadProfiles() {
        var ni = plasmoid.nativeInterface;
        var profileList = ni.getProfileList()

        profileComponent = Qt.createComponent("./Profile.qml");
        if (profileComponent.status !== Component.Ready) {
            print("Profile.qml component not ready.")
            return
        }

        for (var i = 0; i < profileList.length; i++) {
            var name = profileList[i]
            var data = ni.getProfile(name)

            var profile = profileComponent.createObject()
            profile.loadProfile(name, data)

            profilesMap[name] = profile
        }

        sensorsModelBackup = {}
        shadowProfilesMap = {}
        deletedProfiles = []

        // print("Model.ProfileManager loadProfiles " + JSON.stringify(profilesMap))
    }

    function getProfileNames() {
        return Object.keys(profilesMap)
    }

    function getProfile(name) {
        if (!editMode) {
            return profilesMap[name]
        } else {
            return getShadow(name)
        }
    }

    function getShadow(name) {
        if (!name || name === "") {
            return undefined
        }

        if (!(name in shadowProfilesMap)) {
            var p = profilesMap[name]
            var s = profileComponent.createObject()
            s = s.copy(p)

            shadowProfilesMap[name] = s
        }

        return shadowProfilesMap[name]
    }

    function generateName(profileNames) {
        var max = 0
        profileNames.forEach(n => {
            var re = /^New Profile( [0-9]+)$/g
            var match = re.exec(n)
            if (!match || match.length == 1) {
                max = 2
            } else if (match && match[1]) {
                max = Math.max(parseInt(match[1].trim())+1, max)
            }
        })

        var newName = "New Profile" + (max>0 ? " "+max : "")
        return newName
    }

    function createProfile(profileNames) {
        if (!editMode) {
            return undefined
        }

        var profile = profileComponent.createObject()
        profile.name = generateName(profileNames)
        profile.sensors = {}

        shadowProfilesMap[profile.name] = profile

        return profile
    }

    function deleteProfile(name) {
        if (!editMode) {
            return undefined
        }

        if (name in shadowProfilesMap) {
            deletedProfiles.push(name)
        }
    }

    function validateName(newName, profileNames) {
        if (!newName || newName === "" || newName.length > 256) {
            print("validateName: Name length error")
            return false
        }

        if (profileNames.includes(newName)) {
            print("validateName: Another profile name exists.")
            return false
        }

        return true
    }

    function renameProfile(name, newName) {
        if (name in shadowProfilesMap) {
            // Insert a key with the new name but leave the
            // profile.name property as the original.
            // The new name will be applied when the changes are committed.
            shadowProfilesMap[newName] = shadowProfilesMap[name]

            deletedProfiles.push(name)
            delete shadowProfilesMap[name]
        }
    }

    function enterEditMode() {
        sensorsModelBackup = main.sensorsMgr.backupSensorValues()
        editMode = true
    }

    function exitEditMode() {
        main.sensorsMgr.restoreSensorValues(sensorsModelBackup)
        sensorsModelBackup = {}
        shadowProfilesMap = {}
        deletedProfiles = []
        editMode = false
    }

    function applySensorModelValues(profileName, sensorNames) {
        var profile = getProfile(profileName);
        if (!profile) {
            return
        }

        profile.sensors = {}

        var keys = main.sensorsMgr.getKeys()
        for (var i = 0; i < keys.length; i++) {
            if (!sensorNames.includes(keys[i])) {
                continue
            }

            var sensorModel = main.sensorsMgr.getSensor(keys[i])
            profile.sensors[keys[i]] = sensorModel.value
        }
    }

    function commitProfileChanges(profileNames) {
        var keys = Object.keys(shadowProfilesMap)
        for (var i = 0; i < keys.length; i++) {
            var shadowProfile = shadowProfilesMap[keys[i]]
            var profile = profilesMap[shadowProfile.name]

            if (profile === undefined) {
                // added new profile
                profilesMap[shadowProfile.name] = shadowProfile
                profilesMap[shadowProfile.name].name = keys[i]
            } else if (shadowProfile.name !== keys[i]) {
                // renamed profile
                profile.copy(shadowProfile)
                profile.name = keys[i]
                profilesMap[profile.name] = profile
            } else {
                // update existing profile
                profilesMap[shadowProfile.name] = profile.copy(shadowProfile)
            }
        }

        for (var i = 0; i < deletedProfiles.length; i++) {
            var key = deletedProfiles[i]

            var keys = Object.keys(shadowProfilesMap)
            for (var j = 0; j < keys.length; j++) {
                if (shadowProfilesMap[keys[j]].name === key) {
                    delete shadowProfilesMap[keys[j]]
                    break
                }
            }

            var keys = Object.keys(profilesMap)
            for (var j = 0; j < keys.length; j++) {
                if (profilesMap[keys[j]].name === key) {
                    delete profilesMap[keys[j]]
                    break
                }
            }
        }


        keys = Object.keys(profilesMap)
        var ni = plasmoid.nativeInterface;
        for (var i = 0; i < keys.length; i++) {
            var profileModel = profilesMap[keys[i]]
            ni.saveProfile(profileModel.name,
                           JSON.stringify(profileModel.sensors))
        }

        ni.saveProfileList(profileNames)

        print("commitProfileChanges " + JSON.stringify(profilesMap))
    }
}
