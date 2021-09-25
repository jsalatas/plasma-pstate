#!/bin/bash

CPUFREQ_AVAILABLE_GOVERNORS="${CPUFREQ}/scaling_available_governors"
CPUFREQ_SCALING_AVAIL_FREQ=${CPUFREQ}/scaling_available_frequencies

check_cpu_available_governors () {
    [ -f "${CPUFREQ_AVAILABLE_GOVERNORS}" ]
}

read_cpu_available_governors () {
    cpu_available_governors=$(cat "${CPUFREQ_AVAILABLE_GOVERNORS}")
}

check_cpu_scaling_available_frequencies() {
    [ -n "${CPUFREQ_SCALING_AVAIL_FREQ}" ] && [ -f "$CPUFREQ_SCALING_AVAIL_FREQ" ]
}

read_cpu_scaling_available_frequencies () {
    cpu_scaling_available_frequencies=$(cat "${CPUFREQ_SCALING_AVAIL_FREQ}")
}

read_available () {
    json=""
    if check_cpu_available_governors; then
        read_cpu_available_governors
        append_json "\"cpu_governor\":\"${cpu_available_governors}\""
    fi
    if check_cpu_scaling_available_frequencies; then
        read_cpu_scaling_available_frequencies
        append_json "\"cpu_scaling_available_frequencies\":\"${cpu_scaling_available_frequencies}\""
    fi
    echo "{${json}}"
}
