#!/bin/bash

DELL_SMM_HWMON=$(grep -r . /sys/class/hwmon/*/name  2>/dev/null | \
                 grep  "name:dell_smm"  | sed 's/\/name.*//')

check_thermal_mode () {
    smbios-thermal-ctl -g > /dev/null 2>&1
    OUT=$?
    if [ $OUT -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

read_thermal_mode () {
    thermal_mode=$(smbios-thermal-ctl -g | grep -C 1 "Current Thermal Modes:" | \
                   tail -n 1 | awk '{$1=$1;print}' | sed "s/\t//g" | \
                   sed "s/ /-/g" | tr '[:upper:]' '[:lower:]')
}

set_thermal_mode () {
    smbios-thermal-ctl --set-thermal-mode="$1" > /dev/null 2>&1
    read_thermal_mode
    json="{"
    json="${json}\"thermal_mode\":\"${thermal_mode}\""
    json="${json}}"
    echo "$json"
}

check_dell_fan_mode() {
    [ -n "${DELL_SMM_HWMON}" ] && [ -d "${DELL_SMM_HWMON}" ] && \
        [ -f "${DELL_SMM_HWMON}"/pwm1_enable ]
}

read_dell_fan_mode() {
    if [ -f "${DELL_SMM_HWMON}"/pwm1_enable ]; then
        dell_fan_mode="true"
        export dell_fan_mode
    else
        dell_fan_mode="false"
        export dell_fan_mode="false"
    fi
}

return_dell_fan_mode() {
    read_dell_fan_mode
    json="{"
    json="${json}\"dell_fan_mode\":\"${dell_fan_mode}\""
    json="${json}}"
    echo "$json"
}

set_dell_fan_mode() {
    if [ "$1" -lt $((128/2)) ]; then
        printf "2" > "${DELL_SMM_HWMON}"/pwm1_enable 2> /dev/null
        return_dell_fan_mode
        return 0
    fi

    printf 1 > "${DELL_SMM_HWMON}"/pwm1_enable 2> /dev/null

    if [ -f "${DELL_SMM_HWMON}"/pwm1 ]; then
        printf "%s" "$1" > "${DELL_SMM_HWMON}"/pwm1 2> /dev/null
    fi

    if [ -f "${DELL_SMM_HWMON}"/pwm2 ]; then
        printf "%s" "$1" > "${DELL_SMM_HWMON}"/pwm2 2> /dev/null
    fi

    return_dell_fan_mode
}

