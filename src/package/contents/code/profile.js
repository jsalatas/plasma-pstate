
.import "utils.js" as Utils


function deepCopy(p, c) {
    c = c || {};
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


function getValueText(listViewItem, sensorModel, value) {

    var v = (value !== undefined) ? value : sensorModel.value

    var item = listViewItem['item']
    if (item['type'] === 'combobox' || item['type'] === 'radio') {
        var subItems = item['items']
        for (var i = 0; subItems && (i < subItems.length); i++) {
            if (subItems[i]['sensor_value'] === v) {
                return subItems[i]['text']
            }
        }
    }

    return sensorModel.getValueText(v)
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

    var sensors_model = Utils.get_sensors()
    var sensor = sensors_model[item.sensor]

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
    } else if (node.constructor === Object && "items" in node) {
        if ("items" in node) {
            items = node["items"];
        }
    }

    if (node["type"] === "header") {
        header = node
    }
    if (node["type"] === "group") {
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
