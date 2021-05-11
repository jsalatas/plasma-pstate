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
    'cpu_total_available': {'value': undefined, 'unit':'', 'print': to_int},
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
    'cpu_online': {'value': undefined, 'unit':'', 'print': to_int},
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
    'cooler_boost': {'value': undefined, 'unit':'', 'print': to_bool}, 

}

var vendors = {
    'dell': {'provides': ['thermal_mode']},
    'lg-laptop': {'provides': ['lg_battery_charge_limit', 'lg_usb_charge', 'lg_fan_mode']},
    'nvidia': {'provides': ['powermizer']},
    'msi': {'provides': ['cooler_boost']}
}

var model =  [
    {'type': 'header', 'text': 'Processor Settings', 'icon': 'd',
        'sensors': ['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'],
        'items': [
            {'type': 'group', 'text': 'CPU Frequencies', 'items' :[
                {'type': 'slider', 'text': 'Min perf', 'min': 0, 'max': 100, 'sensor': 'cpu_min_perf'},
                {'type': 'slider', 'text': 'Max perf', 'min': 0, 'max': 100, 'sensor': 'cpu_max_perf'},
                {'type': 'switch', 'text': 'Turbo', 'sensor': 'cpu_turbo'}
            ]},
            {'type': 'group', 'text': 'Online CPUs', 'items' :[
                {'type': 'slider', 'text': 'CPUs', 'min': 0, 'max': 'cpu_total_available', 'sensor': 'cpu_online'},
            ]},
            {'type': 'group', 'text': 'GPU Frequencies', 'visible': 'showIntelGPU', 'items' :[
                {'type': 'slider', 'text': 'Min freq', 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_min_freq'},
                {'type': 'slider', 'text': 'Max freq', 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_max_freq'},
                {'type': 'slider', 'text': 'Boost freq', 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_boost_freq'},
            ]},
            {'type': 'radio', 'text': 'CPU Governor', 'sensor': 'cpu_governor', 'items' :[
                {'symbol': 'a', 'text': 'Performance', 'sensor_value': 'performance'},
                {'symbol': 'k', 'text': 'Balance Performance', 'sensor_value': 'ondemand'},
                {'symbol': 'l', 'text': 'Balance Power', 'sensor_value': 'conservative'},
                {'symbol': 'f', 'text': 'Powersave', 'sensor_value': 'powersave'}
            ]}
        ]
    },
    {'type': 'header', 'text': 'Energy Performance', 'icon': 'h',
        'sensors': ['battery_percentage', 'battery_remaining_time'],
        'items': [
            {'type': 'radio', 'text': '', 'sensor': 'energy_perf', 'items' :[
                {'symbol': 'i', 'text': 'Default', 'sensor_value': 'default'},
                {'symbol': 'a', 'text': 'Performance', 'sensor_value': 'performance'},
                {'symbol': 'k', 'text': 'Balance Performance', 'sensor_value': 'balance_performance'},
                {'symbol': 'l', 'text': 'Balance Power', 'sensor_value': 'balance_power'},
                {'symbol': 'f', 'text': 'Power', 'sensor_value': 'power'}
            ]}
        ]
    },
    {'type': 'header', 'text': 'Thermal Management', 'icon': 'b',
        'vendors': ['dell'],
        'sensors': ['package_temp', 'fan_speeds'],
        'items': [
            {'type': 'radio', 'text': '', 'sensor': 'thermal_mode', 'items' :[
                 {'symbol': 'e', 'text': 'Performance', 'sensor_value': 'performance'},
                 {'symbol': 'j', 'text': 'Balanced', 'sensor_value': 'balanced'},
                 {'symbol': 'g', 'text': 'Cool Bottom', 'sensor_value': 'cool-bottom'},
                {'symbol': 'c', 'text': 'Quiet', 'sensor_value': 'quiet'}
            ]}
        ]
    }, 
    {'type': 'header', 'text': 'Power Supply Management', 'icon': 'm',
        'vendors': ['lg-laptop'], 
        'items': [
            {'type': 'switch', 'text': 'Battery Limit', 'sensor': 'lg_battery_charge_limit'},
            {'type': 'switch', 'text': 'USB Charge', 'sensor': 'lg_usb_charge'}
        ]
    },
    {'type': 'header', 'text': 'Fan Control', 'icon': 'n',
        'vendors': ['lg-laptop'], 
        'items': [
            {'type': 'switch', 'text': 'Silent Mode', 'sensor': 'lg_fan_mode'}
        ]
    },
    {'type': 'header', 'text': 'Nvidia Settings', 'icon': 'o',
        'vendors': ['nvidia'],
        'items': [
            {'type': 'combobox', 'text': 'PowerMizer', 'sensor': 'powermizer', 'items' :[
                 {'text': 'Adaptive', 'sensor_value': '0'},
                 {'text': 'Prefer Max Performance', 'sensor_value': '1'},
                {'text': 'Auto', 'sensor_value': '2'}
            ]}
        ]
    },
    {'type': 'header', 'text': 'MSI Settings', 'icon': 'b',
        'vendors': ['msi'], 
        'items': [
            {'type': 'switch', 'text': 'Cooler Boost', 'sensor': 'cooler_boost'}
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

