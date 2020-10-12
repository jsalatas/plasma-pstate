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

function to_int(item) {
    var val = Math.round(parseFloat(item['value']), 0);
    return 0 == val || val ? val  + item['unit'] : '';
}

function array_to_int(items) {
    var res = '';
    var keys = Object.keys(items['value'])
    for (var i=0; i< keys.length; i++) {
        var item = items['value'][keys[i]]
        var val = Math.round(parseFloat(item), 0);
        if(0 == val || val) {
            if(res) {
                res += ' | '
            }
            res += val + items['unit'];
        }
    };
    return res;
}

function to_time(item) {
    var val = Math.round(parseFloat(item['value']), 0);
    var hours   = Math.floor(val / 3600);
    var minutes = Math.floor((val - (hours * 3600)) / 60);

    if (minutes < 10) {minutes = "0"+minutes;}
    return hours ? hours+':'+minutes : '';
}

function to_bool(item) {
    return parseInt(item['value'], 10) == 1;
}

function to_string(item) {
    return item['value'];
}

var sensors = {
    // Informational
    'cpu_cur_load': {'value': undefined, 'unit':'%', 'print': to_int},
    'cpu_cur_freq': {'value': undefined, 'unit':' MHz', 'print': to_int},
    'gpu_cur_freq': {'value': undefined, 'unit':' MHz', 'print': to_int},
    'gpu_min_limit': {'value': undefined, 'unit':'', 'print': to_int},
    'gpu_max_limit': {'value': undefined, 'unit':'', 'print': to_int},
    'battery_percentage': {'value': undefined, 'unit': '%', 'print': to_int},
    'battery_remaining_time': {'value': undefined, 'print': to_time},
    'package_temp': {'value': undefined, 'unit': ' \u2103', 'print': to_int},
    'fan_speeds': {'value': {}, 'unit': ' RPM', 'print': array_to_int},
    // Tunable
    'cpu_min_perf': {'value': undefined, 'unit':'%', 'print': to_int},
    'cpu_max_perf': {'value': undefined, 'unit':'%', 'print': to_int},
    'cpu_turbo': {'value': undefined, 'unit':'', 'print': to_bool},
    'gpu_min_freq': {'value': undefined, 'unit':' MHz', 'print': to_int},
    'gpu_max_freq': {'value': undefined, 'unit':' MHz', 'print': to_int},
    'gpu_boost_freq': {'value': undefined, 'unit':' MHz', 'print': to_int},
    'cpu_governor': {'value': undefined, 'unit':'', 'print': to_string},
    'energy_perf': {'value': undefined, 'unit':'', 'print': to_string},
    'thermal_mode': {'value': undefined, 'unit':'', 'print': to_string}, 
    'lg_battery_charge_limit': {'value': undefined, 'unit':'', 'print': to_bool},
    'lg_usb_charge': {'value': undefined, 'unit':'', 'print': to_bool},
    'lg_fan_mode': {'value': undefined, 'unit':'', 'print': to_bool},
    'powermizer': {'value': undefined, 'unit':'', 'print': to_string}, 

}

var vendors = {
    'dell': {'provides': ['thermal_mode']},
    'lg-laptop': {'provides': ['lg_battery_charge_limit', 'lg_usb_charge', 'lg_fan_mode']},
    'nvidia': {'provides': ['powermizer']}
}

var model =  [
    {'type': 'header', 'text': i18n("Processor Settings"), 'icon': 'd',
        'sensors': ['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'],
        'items': [
            {'type': 'group', 'text': i18n("CPU Frequencies"), 'items' :[
                {'type': 'slider', 'text': i18n("Min perf"), 'min': 0, 'max': 100, 'sensor': 'cpu_min_perf'},
                {'type': 'slider', 'text': i18n("Max perf"), 'min': 0, 'max': 100, 'sensor': 'cpu_max_perf'},
                {'type': 'switch', 'text': i18n("Turbo"), 'sensor': 'cpu_turbo'}
            ]},
            {'type': 'group', 'text': i18n("GPU Frequencies"), 'visible': 'showIntelGPU', 'items' :[
                {'type': 'slider', 'text': i18n("Min freq"), 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_min_freq'},
                {'type': 'slider', 'text': i18n("Max freq"), 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_max_freq'},
                {'type': 'slider', 'text': i18n("Boost freq"), 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_boost_freq'},
            ]},
            {'type': 'radio', 'text': i18n("CPU Governor"), 'sensor': 'cpu_governor', 'items' :[
                {'symbol': 'a', 'text': i18n("Performance"), 'sensor_value': 'performance'},
                {'symbol': 'f', 'text': i18n("Powersave"), 'sensor_value': 'powersave'}
            ]}
        ]
    },
    {'type': 'header', 'text': i18n("Energy Performance"), 'icon': 'h',
        'sensors': ['battery_percentage', 'battery_remaining_time'],
        'items': [
            {'type': 'radio', 'text': '', 'sensor': 'energy_perf', 'items' :[
                {'symbol': 'i', 'text': i18n("Default"), 'sensor_value': 'default'},
                {'symbol': 'a', 'text': i18n("Performance"), 'sensor_value': 'performance'},
                {'symbol': 'k', 'text': i18n("Balance Performance"), 'sensor_value': 'balance_performance'},
                {'symbol': 'l', 'text': i18n("Balance Power"), 'sensor_value': 'balance_power'},
                {'symbol': 'f', 'text': i18n("Power"), 'sensor_value': 'power'}
            ]}
        ]
    },
    {'type': 'header', 'text': i18n("Thermal Management"), 'icon': 'b',
        'vendors': ['dell'],
        'sensors': ['package_temp', 'fan_speeds'],
        'items': [
            {'type': 'radio', 'text': '', 'sensor': 'thermal_mode', 'items' :[
                 {'symbol': 'e', 'text': i18n("Performance"), 'sensor_value': 'performance'},
                 {'symbol': 'j', 'text': i18n("Balanced"), 'sensor_value': 'balanced'},
                 {'symbol': 'g', 'text': i18n("Cool Bottom"), 'sensor_value': 'cool-bottom'},
                {'symbol': 'c', 'text': i18n("Quiet"), 'sensor_value': 'quiet'}
            ]}
        ]
    }, 
    {'type': 'header', 'text': i18n("Power Supply Management"), 'icon': 'm',
        'vendors': ['lg-laptop'], 
        'items': [
            {'type': 'switch', 'text': i18n("Battery Limit"), 'sensor': 'lg_battery_charge_limit'},
            {'type': 'switch', 'text': i18n("USB Charge"), 'sensor': 'lg_usb_charge'}
        ]
    },
    {'type': 'header', 'text': i18n("Fan Control"), 'icon': 'n',
        'vendors': ['lg-laptop'], 
        'items': [
            {'type': 'switch', 'text': i18n("Silent Mode"), 'sensor': 'lg_fan_mode'}
        ]
    },
    {'type': 'header', 'text': i18n("Nvidia Settings"), 'icon': 'o',
        'vendors': ['nvidia'],
        'items': [
            {'type': 'combobox', 'text': i18n("PowerMizer"), 'sensor': 'powermizer', 'items' :[
                 {'text': i18n("Adaptive"), 'sensor_value': '0'},
                 {'text': i18n("Prefer Max Performance"), 'sensor_value': '1'},
                {'text': i18n("Auto"), 'sensor_value': '2'}
            ]}
        ]
    }
]

function get_model() {
    return model;
}

function get_sensors() {
    return sensors;
}

function get_vendors() {
    return vendors;
}

