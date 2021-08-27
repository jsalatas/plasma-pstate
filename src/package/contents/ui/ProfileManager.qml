import QtQuick 2.0

import '../code/utils.js' as Utils
import '../code/profile.js' as ProfileUtils


Item {

    /* required */ property var sensors_model

    property bool hasNativeBackend: plasmoid.nativeInterface.getProfileList !== undefined

    property var editMode: false

    property var profiles: undefined
    property var profileNames: undefined

    property var sensorsModelReal: undefined
    property var sensorsModelShadow: undefined
    property var profilesShadow: undefined
    property var deletedProfiles: undefined


    function loadProfiles() {
        var ni = plasmoid.nativeInterface;

        var profileList = ni.getProfileList()
        profileNames = profileList

        profiles = []
        for (var i = 0; i < profileList.length; i++) {
            var name = profileList[i]
            var profile = ni.getProfile(name)

            profiles.push({
                "name": name,
                "sensors": JSON.parse(profile)
            })
        }
    }

    Component.onCompleted: {
        if (!hasNativeBackend) {
            print("Profiles not supported.")
            return
        }

        loadProfiles()

        print("ProfileManager onCompleted profileNames = " +
               JSON.stringify(profileNames))
        print("ProfileManager onCompleted profiles = " +
              JSON.stringify(profiles))
    }

    function enterEditMode() {

        // back up sensors_model
        sensorsModelReal = ProfileUtils.deepCopy(sensors_model)
        profilesShadow = []
        sensorsModelShadow = []
        deletedProfiles = []

        editMode = true
    }

    function exitEditMode(argument) {
        profileNames = profiles.map(p => p.name)

        sensors_model = ProfileUtils.deepCopy(sensorsModelReal)
        sensorsModelReal = undefined
        deletedProfiles = undefined
        profilesShadow = undefined
        sensorsModelShadow = undefined

        editMode = false
    }

    function getProfile(name) {
        if (!editMode) {
            return ProfileUtils.findProfile(profiles, name)
        } else {
            return shadowCopy(name)    
        }
    }

    function shadowCopy(name) {
        if (!name) {
            return undefined
        }

        var profile = ProfileUtils.findProfile(profilesShadow, name)
        if (profile) {
            return profile
        }

        var profile = ProfileUtils.findProfile(profiles, name)
        if (profile) {
            profilesShadow.push(ProfileUtils.deepCopy(profile))
        } else {
            profile = { "name": name, "sensors": {} }
            profilesShadow.push(profile)
            profileNames = profileNames.concat([name])
        }

        sensorsModelShadow.push(ProfileUtils.deepCopy(sensors_model))

        var copyIdx = profilesShadow.length - 1
        sensors_model = sensorsModelShadow[copyIdx]

        var idx = profileNames.indexOf(name)
        if (idx === -1) {
            print("Mgr.shadowCopy: error profile name wasn't added")
            console.trace()
        }

        return profile
    }

    function createProfile() {
        if (!editMode) {
            return undefined
        }

        // Generate a unique name
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
        var profile = shadowCopy(newName)

        profileNames.push(profile.name)

        return profile
    }

    function deleteProfile(name) {
        if (!editMode) {
            return
        }

        if (!profileNames.includes(name)) {
            print("error: deleteProfile: No profile named " + name)
            return
        }

        var idx = ProfileUtils.findProfileIndex(profilesShadow, name)
        if (idx !== -1) {
            profilesShadow.splice(idx, 1)
        }

        deletedProfiles.push(name)
        profileNames = profileNames.filter(n => n !== name)
    }

    function validateName(newName) {
        if (!newName || newName == "" || newName.length > 256) {
            return false
        }

        if (profileNames.includes(newName)) {
            return false
        }

        return true
    }

    function setProfileName(name, newName) {
        if (!editMode) {
            return false
        }

        if (name === newName) {
            return false
        }

        if (!validateName(newName)) {
            print("error: applyProfileName: Invalid name")
            console.trace()
            return false
        }

        var profile = ProfileUtils.findProfile(profilesShadow, name)
        if (!profile) {
            print("error: applyProfileName: No profiled named \"" + name +
                  "\" to rename.")
            console.trace()
            return false
        }

        if (profileNames.includes(newName)) {
            print("error: applyProfileName: A profile named \"" + newName +
                  "\" already exists.")
            console.trace()
            return false
        }

        profile["old_name"] = name
        profile.name = newName

        var idx = profileNames.indexOf(name)
        profileNames[idx] = newName

        return true
    }

    function saveProfiles() {
        if (!editMode) {
            return
        }

        // Update settings file
        for (var i = profiles.length - 1; i >= 0; i--) {
            if (deletedProfiles.includes(profiles[i].name)) {
                var profile = profiles.splice(i, 1)
                plasmoid.nativeInterface.deleteProfile(profile[0].name)
            }
        }

        for (var i = 0; i < profilesShadow.length; i++) {
            var oldName = profilesShadow[i]["old_name"]
            var name = oldName ? oldName : profilesShadow[i].name
            var idx = ProfileUtils.findProfileIndex(profiles, name)

            if (idx > -1) {
                delete profilesShadow[i]["old_name"]
                profiles[idx] = ProfileUtils.deepCopy(profilesShadow[i])
            } else {
                profiles.push(ProfileUtils.deepCopy(profilesShadow[i]))
                idx = profiles.length - 1
            }

            if (oldName) {
                plasmoid.nativeInterface.deleteProfile(oldName)
            }
            
            plasmoid.nativeInterface
                .saveProfile(profiles[idx].name,
                             JSON.stringify(profiles[idx].sensors))
        }

    }
}
