
function deepCopy(p, c) {
    var c = c || {};
    for (var i in p) {
        if (typeof p[i] === 'object') {
            c[i] = (p[i].constructor === Array) ? [] : {};
            deepCopy(p[i], c[i]);
        } else {
            c[i] = p[i];
        }
    }
    return c;
}

/*
 * Push a sensor item to the array
 *
 * arr: Array of sensor view model items
 * item: An item to push
 * header: The items header view model
 * group: The items group view model (if it exists)
 */
function pushValidItem(arr, item, header, group) {
    if (item["type"] === undefined || item["sensor"] === undefined) {
        return
    }
    // if (!Utils.is_writeable(sensors_model[item.sensor])) {
    //     return
    // }

    var sensor = main.sensors_model[item.sensor]

    arr.push({
        "sensor": item.sensor,
        "item": item,
        "header": header,
        "group": group ? group : {},
        "valueText": "-",
        "headerText": header.text,
        "checked": false
    })
}

/*
 * Traverse the sensor view model
 */
function stepItems(arr, node, header, group) {
    // print("stepItems node = " + JSON.stringify(node))
    var items = []

    if (Array.isArray(node)) {
        items = node
    } else if (node.constructor == Object && "items" in node) {
        if ("items" in node) {
            items = node["items"];
        }
    }

    if (node["type"] == "header") {
        header = node
    }
    if (node["type"] == "group") {
        group = node
    }

    for (var i = 0; items && i < items.length; i++) {
        var item = items[i];

        pushValidItem(arr, item, header, group);
        stepItems(arr, item, header, group);
    }
}

/*
 * Get a flatted array of all tunable sensor items from the view model
 */
function findSensorItems(model) {
    var arr = []
    stepItems(arr, model, undefined, undefined)
    return arr
}

function findProfileIndex(profiles, name) {
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].name === name) {
            return i
        }
    }
    return -1
}

function findProfile(profiles, name) {
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].name === name) {
            return profiles[i]
        }
    }
    return undefined
}
