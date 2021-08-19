#!/bin/bash

CPUFREQ_EPP="${CPUFREQ}/energy_performance_preference"

check_cpu_governor () {
    [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]
}

read_cpu_governor () {
    cpu_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
}

set_cpu_governor () {
    gov=$1
    if [ -n "$gov" ]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            printf '%s\n' "$gov" > "$cpu" 2> /dev/null
        done
    fi
    read_cpu_governor
    json="{"
    json="${json}\"cpu_governor\":\"${cpu_governor}\""
    json="${json}}"
    echo "$json"
}

check_energy_perf() {
    [ -f "${CPUFREQ_EPP}" ]
}

read_energy_perf () {
    energy_perf=$(cat "${CPUFREQ_EPP}" 2>/dev/null)
    if [ -z "$energy_perf" ]; then
        energy_perf=$(x86_energy_perf_policy -r 2>/dev/null | grep -v 'HWP_' | \
        sed -r 's/://;
                s/(0x0000000000000000|EPB 0)/performance/;
                s/(0x0000000000000004|EPB 4)/balance_performance/;
                s/(0x0000000000000006|EPB 6)/default/;
                s/(0x0000000000000008|EPB 8)/balance_power/;
                s/(0x000000000000000f|EPB 15)/power/' | \
        awk '{ printf "%s\n", $2; }' | head -n 1)
    fi
}

set_energy_perf () {
    energyperf=$1
    if [ -n "$energyperf" ]; then
        if [ -f "${CPUFREQ_EPP}" ]; then
            for cpu in ${CPUFREQ_EPP}; do
                printf '%s\n' "$energyperf" > "$cpu" 2> /dev/null
            done
        else
            pnum=$(echo "$energyperf" | sed -r 's/^performance$/0/;
                                s/^balance_performance$/4/;
                                s/^(default|normal)$/6/;
                                s/^balance_power?$/8/;
                                s/^power(save)?$/15/')

            x86_energy_perf_policy "$pnum" > /dev/null 2>&1
        fi
    fi
    read_energy_perf
    json="{"
    json="${json}\"energy_perf\":\"${energy_perf}\""
    json="${json}}"
    echo "$json"
}
