#!/bin/bash

export CPUFREQ=/sys/devices/system/cpu/cpu0/cpufreq

BASEDIR=$(dirname "$0")
# shellcheck disable=SC1091
source "${BASEDIR}"/cpu.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/intel.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/nvidia.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/lg_laptop.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/dell_laptop.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/sysfs_available.sh

sensors_model=(
    # "kernel_version"
    "cpu_min_perf"
    "cpu_max_perf"
    "cpu_turbo"
    "gpu_min_freq"
    "gpu_max_freq"
    "gpu_min_limit"
    "gpu_max_limit"
    "gpu_boost_freq"
    "gpu_cur_freq"
    "cpu_governor"
    "energy_perf"
    "thermal_mode"
    "lg_battery_charge_limit"
    "lg_fan_mode"
    "lg_usb_charge"
    "powermizer"
    "nvidia_runtime_status"
    "intel_tcc_cur_state"
    "intel_tcc_max_state"
    "intel_rapl_short"
    "intel_rapl_long"
    "dell_fan_mode"
    "dell_fan_pwm"
    "cpufreq_scaling_min_freq"
    "cpufreq_scaling_max_freq"
)


# Append a json key/value to the string variable 'json'.
#  e.g.
#   append_json '"foo":"bar"'
# 1: A json key/value
append_json() {
    json="${json}${json:+,}${1}"
}

# Helper macro to read sensor data and append it to the json string
# 1: Sensor name
append_macro() {
    _cmd="
        if check_${1}; then
            read_${1};
            append_json $(printf \"\\\\\"%s\\\\\":\\\\\"%s\\\\\"\" "${1}" \$\{"${1}"\});
        fi
    "
    # echo "$_cmd"
    eval "$_cmd"
}

generate_read_sensor_func() {
    _cmd="read_sensor() {
            case \"\$1\" in
         "
    for sensor in "${sensors_model[@]}"
    do
        _subcmd="
                \"${sensor}\")
                    if check_${sensor}; then
                        read_${sensor};
                        if [ -n \"\${${sensor}}\" ]; then
                            append_json $(printf \"\\\\\"%s\\\\\":\\\\\"%s\\\\\"\" "${sensor}" \$\{"${sensor}"\});
                        fi
                    fi
                    ;;
                "
        _cmd="${_cmd}${_subcmd}"
    done
    _cmd="${_cmd}
            esac
         }"
    # echo "${_cmd}"
    eval "${_cmd}"
}

is_valid_sensor() {
    _arg=$(printf '%s\n' "${sensors_model[@]}" | grep -P "^${1}\$")
    if [ -n "${_arg}" ]; then
        echo "${_arg}"
    else
        echo ""
    fi
}

read_all () {
    json=""

    for sensor in "${sensors_model[@]}"
    do
        read_sensor "${sensor}"
    done

    echo "{${json}}"
}

read_some() {
    _all_sensors=$(printf '%s\n' "${sensors_model[@]}")

    json=""

    for sensor in "${@}"
    do
        echo "${_all_sensors}" | grep -q -P "^${sensor}\$" || continue
        read_sensor "${sensor}"
    done

    echo "{${json}}"
}

write_sensor() {
    _sensor=$(is_valid_sensor "$1")
    if [ -n "${_sensor}" ]; then
        eval "set_${_sensor}" "${@:2}"
        return 0
    fi

    return 1
}

list_sensors() {
    _out=
    for sensor in "${sensors_model[@]}"
    do
        _out="${_out:+$_out }${sensor}"
    done
    echo "${_out}"
}

daemon() {
    export DAEMON_MODE=1
    while read -n 1024 -r -a line
    do
        main "${line[@]}"
    done < "/dev/stdin"
}

print_usage() {
    echo "Usage:"
    echo "1: set_prefs.sh -write-sensor <sensor-name> <value>"
    echo "2: set_prefs.sh -read-all"
    echo "3: set_prefs.sh -read-available"
    echo "4: set_prefs.sh -read-some"
    exit 3
}

print_json_error() {
    if [ ! ${DAEMON_MODE} ]; then
        print_usage
    else
        stdbuf -oL printf "{\"error\":\"invalid arg\"}" 1>&2
        echo ""
    fi
}

main() {
    case $1 in

        "-read-all")
            read_all
            ;;

        "-read-available")
            read_available
            ;;

        "-read-some")
            read_some "${@:2}"
            ;;

        "-list-sensors")
            list_sensors
            ;;

        "-daemon")
            daemon "$@"
            ;;

        "-exit")
            exit 0
            ;;

        "-write-sensor")
            shift 1
            if write_sensor "${@}"; then
                return 0
            fi

            print_json_error
            ;;

        *)
            print_json_error
            ;;
    esac
}

generate_read_sensor_func
main "$@"
