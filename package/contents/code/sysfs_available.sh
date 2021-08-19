#!/bin/bash

CPUFREQ_AVAILABLE_GOVERNORS="${CPUFREQ}/scaling_available_governors"

check_cpu_available_governors () {
    [ -f "${CPUFREQ_AVAILABLE_GOVERNORS}" ]
}

read_cpu_available_governors () {
    cpu_available_governors=$(cat "${CPUFREQ_AVAILABLE_GOVERNORS}")
}

read_available () {
    json="{"
    if check_cpu_available_governors; then
        read_cpu_available_governors
        append_json "\"cpu_governor\":\"${cpu_available_governors}\""
    fi
    json="${json}}"
    echo $json
}
