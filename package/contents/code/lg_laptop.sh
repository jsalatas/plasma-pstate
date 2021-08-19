#!/bin/bash

LG_LAPTOP_DRIVER=/sys/devices/platform/lg-laptop
LG_FAN_MODE=$LG_LAPTOP_DRIVER/fan_mode
LG_BATTERY_CHARGE_LIMIT=$LG_LAPTOP_DRIVER/battery_care_limit
LG_USB_CHARGE=$LG_LAPTOP_DRIVER/usb_charge


check_lg_battery_charge_limit() {
    [ -d $LG_LAPTOP_DRIVER ]
}

read_lg_battery_charge_limit() {
    check_lg_battery_charge_limit || return 1

    lg_battery_charge_limit=$(cat $LG_BATTERY_CHARGE_LIMIT)
    if [ "$lg_battery_charge_limit" = "80" ]; then
        lg_battery_charge_limit="true"
    else
        lg_battery_charge_limit="false"
    fi
}

set_lg_battery_charge_limit(){
    enabled=$1
    if [ -n "$enabled" ]; then
        if [ "$enabled" = "true" ]; then
            printf '80\n' > $LG_BATTERY_CHARGE_LIMIT 2> /dev/null
        else
            printf '100\n' > $LG_BATTERY_CHARGE_LIMIT 2> /dev/null
        fi
    fi
}

check_lg_fan_mode() {
    [ -d $LG_LAPTOP_DRIVER ]
}

read_lg_fan_mode() {
    check_lg_fan_mode || return 1

    lg_usb_charge=$(cat $LG_USB_CHARGE)
    if [ "$lg_usb_charge" = "1" ]; then
        lg_usb_charge="true"
    else
        lg_usb_charge="false"
    fi
}

set_lg_fan_mode() {
    enabled=$1
    if [ -n "$enabled" ]; then
        if [ "$enabled" = "true" ]; then
           printf '0\n' > $LG_FAN_MODE 2> /dev/null
        else
           printf '1\n' > $LG_FAN_MODE 2> /dev/null
        fi
    fi
}

check_lg_usb_charge() {
    [ -d $LG_LAPTOP_DRIVER ]
}

read_lg_usb_charge() {
    check_lg_usb_charge || return 1

    lg_usb_charge=$(cat $LG_USB_CHARGE)
    if [ "$lg_usb_charge" = "1" ]; then
        lg_usb_charge="true"
    else
        lg_usb_charge="false"
    fi
}

set_lg_usb_charge()  {
    enabled=$1
    if [ -n "$enabled" ]; then
        if [ "$enabled" = "true" ]; then
           printf '1\n' > $LG_USB_CHARGE 2> /dev/null
        else
           printf '0\n' > $LG_USB_CHARGE 2> /dev/null
        fi
    fi
}

