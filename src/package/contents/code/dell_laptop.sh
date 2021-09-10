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
        dell_fan_mode="0"
    fi
    export dell_fan_mode
}

return_dell_fan_mode() {
    read_dell_fan_mode
    json="{"
    json="${json}\"dell_fan_mode\":\"${dell_fan_mode}\""
    json="${json}}"
    echo "$json"
}

set_dell_fan_mode() {
    printf "%s" "${1}" > "${DELL_SMM_HWMON}"/pwm1_enable 2> /dev/null
    echo "{\"dell_fan_mode\":\"${1}\"}"
}


check_dell_fan_pwm() {
    [ -n "${DELL_SMM_HWMON}" ] && [ -d "${DELL_SMM_HWMON}" ] && \
        [ -f "${DELL_SMM_HWMON}"/pwm1_enable ]
}

read_dell_fan_pwm() {
    mapfile -t _pwm < <(find "${DELL_SMM_HWMON}"/pwm? -printf "%f\n")
    dell_fan_pwm=${_pwm[*]}
    export dell_fan_pwm

    if [ -f "${DELL_SMM_HWMON}"/pwm1 ]; then
        dell_fan_pwm1=$(cat "${DELL_SMM_HWMON}"/pwm1)
        append_json '"dell_fan_pwm\/pwm1":"'"${dell_fan_pwm1}"'"'
    fi

    if [ -f "${DELL_SMM_HWMON}"/pwm2 ]; then
        dell_fan_pwm2=$(cat "${DELL_SMM_HWMON}"/pwm2)
        append_json '"dell_fan_pwm\/pwm2":"'"${dell_fan_pwm2}"'"'
    fi

    if [ -f "${DELL_SMM_HWMON}"/pwm3 ]; then
        dell_fan_pwm3=$(cat "${DELL_SMM_HWMON}"/pwm3)
        append_json '"dell_fan_pwm\/pwm3":"'"${dell_fan_pwm3}"'"'
    fi
}

set_dell_fan_pwm() {
    case "${1}" in
        pwm1|pwm2|pwm3)
            printf "%s" "${2}" > "${DELL_SMM_HWMON}/${1}" 2> /dev/null
            ;;
    esac

    echo "{}"
}
