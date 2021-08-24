#!/bin/bash

INTEL_PSTATE=/sys/devices/system/cpu/intel_pstate
CPU_MIN_PERF=$INTEL_PSTATE/min_perf_pct
CPU_MAX_PERF=$INTEL_PSTATE/max_perf_pct

if [ -f $INTEL_PSTATE/no_turbo ]; then
    CPU_TURBO=$INTEL_PSTATE/no_turbo
    CPU_TURBO_ON="0"
    CPU_TURBO_OFF="1"
fi

GPU=$(grep -r . /sys/class/drm/card?/device/vendor 2>/dev/null | \
      grep vendor:0x8086 | sed 's/\/device\/vendor:.*//' | head -n1)
GPU_MIN_FREQ=$GPU/gt_min_freq_mhz
GPU_MAX_FREQ=$GPU/gt_max_freq_mhz
GPU_MIN_LIMIT=$GPU/gt_RP1_freq_mhz
GPU_MAX_LIMIT=$GPU/gt_RP0_freq_mhz
GPU_BOOST_FREQ=$GPU/gt_boost_freq_mhz
GPU_CUR_FREQ=$GPU/gt_cur_freq_mhz

INTEL_TCC=$(grep -r . /sys/class/thermal/*/type 2>/dev/null | \
            grep  "type:TCC Offset" | sed 's/\/type.*//')

INTEL_RAPL=$(grep -r . /sys/class/powercap/intel-rapl/*/name 2>/dev/null | \
             grep name:package-0 | sed 's/\/name:package-0//')
INTEL_RAPL_LONG=$(grep . "${INTEL_RAPL}"/constraint_*_name 2>/dev/null | \
                  grep long_term | sed 's/\/*_name:long_term//')
INTEL_RAPL_LONG=${INTEL_RAPL_LONG}_power_limit_uw
INTEL_RAPL_SHORT=$(grep . "${INTEL_RAPL}"/constraint_*_name 2>/dev/null | \
                   grep short_term | sed 's/\/*_name:short_term//')
INTEL_RAPL_SHORT=${INTEL_RAPL_SHORT}_power_limit_uw


check_cpu_min_perf () {
    [ -n "$CPU_MIN_PERF" ] && [ -f $CPU_MIN_PERF ]
}

read_cpu_min_perf () {
    cpu_min_perf=$(cat $CPU_MIN_PERF)
}

set_cpu_min_perf () {
    minperf=$1
    if [ -n "$minperf" ] && [ "$minperf" != "0" ]; then
        printf '%s\n' "$minperf" > $CPU_MIN_PERF 2> /dev/null
    fi
    read_cpu_min_perf
    json="{"
    json="${json}\"cpu_min_perf\":\"${cpu_min_perf}\""
    json="${json}}"
    echo "$json"
}

check_cpu_max_perf () {
    [ -n "$CPU_MAX_PERF" ] && [ -f $CPU_MAX_PERF ]
}

read_cpu_max_perf () {
    cpu_max_perf=$(cat $CPU_MAX_PERF)
}

append_cpu_max_perf() {
    check_cpu_max_perf || return 1
    read_cpu_max_perf
    append_json "\"cpu_max_perf\":\"${cpu_max_perf}\""
}

set_cpu_max_perf () {
    maxperf=$1
    if [ -n "$maxperf" ] && [ "$maxperf" != "0" ]; then
        printf '%s\n' "$maxperf" > $CPU_MAX_PERF 2> /dev/null
    fi
    read_cpu_max_perf
    json="{"
    json="${json}\"cpu_max_perf\":\"${cpu_max_perf}\""
    json="${json}}"
    echo "$json"
}

check_cpu_turbo () {
    [ -n "$CPU_TURBO" ] && [ -f $CPU_TURBO ]
}

read_cpu_turbo () {
    cpu_turbo=$(cat $CPU_TURBO)
    if [ "$cpu_turbo" = "$CPU_TURBO_OFF" ]; then
        cpu_turbo="false"
    else
        cpu_turbo="true"
    fi
}

append_cpu_turbo() {
    check_cpu_turbo || return 1
    read_cpu_turbo
    append_json "\"cpu_turbo\":\"${cpu_turbo}\""
}

set_cpu_turbo () {
    turbo=$1
    if [ -n "$turbo" ]; then
        if [ "$turbo" = "true" ]; then
            printf "%s" "$CPU_TURBO_ON\n" > $CPU_TURBO 2> /dev/null
        else
            printf "%s" "$CPU_TURBO_OFF\n" > $CPU_TURBO 2> /dev/null
        fi
    fi
    read_cpu_turbo
    json="{"
    json="${json}\"cpu_turbo\":\"${cpu_turbo}\""
    json="${json}}"
    echo "$json"
}

check_gpu_min_freq () {
    [ -n "$GPU_MIN_FREQ" ] && [ -f $GPU_MIN_FREQ ]
}

read_gpu_min_freq () {
    gpu_min_freq=$(cat $GPU_MIN_FREQ)
}

append_gpu_min_freq() {
    check_gpu_min_freq || return 1
    read_gpu_min_freq
    append_json "\"gpu_min_freq\":\"${gpu_min_freq}\""
}

set_gpu_min_freq () {
    gpuminfreq=$1
    if [ -n "$gpuminfreq" ] && [ "$gpuminfreq" != "0" ]; then
        printf '%s\n' "$gpuminfreq" > $GPU_MIN_FREQ 2> /dev/null
    fi
    read_gpu_min_freq
    json="{"
    json="${json}\"gpu_min_freq\":\"${gpu_min_freq}\""
    json="${json}}"
    echo "$json"
}

check_gpu_max_freq () {
    [ -n "$GPU_MAX_FREQ" ] && [ -f $GPU_MAX_FREQ ]
}

read_gpu_max_freq () {
    gpu_max_freq=$(cat $GPU_MAX_FREQ)
}

set_gpu_max_freq () {
    gpumaxfreq=$1
    if [ -n "$gpumaxfreq" ] && [ "$gpumaxfreq" != "0" ]; then
        printf '%s\n' "$gpumaxfreq" > $GPU_MAX_FREQ 2> /dev/null
    fi
    read_gpu_max_freq
    json="{"
    json="${json}\"gpu_max_freq\":\"${gpu_max_freq}\""
    json="${json}}"
    echo "$json"
}

check_gpu_min_limit () {
    [ -n "$GPU_MIN_LIMIT" ] && [ -f $GPU_MIN_LIMIT ]
}

read_gpu_min_limit () {
    gpu_min_limit="$(cat ${GPU_MIN_LIMIT})"
    export gpu_min_limit
}

check_gpu_max_limit () {
    [ -n "$GPU_MAX_LIMIT" ] && [ -f $GPU_MAX_LIMIT ]
}

read_gpu_max_limit () {
    gpu_max_limit="$(cat ${GPU_MAX_LIMIT})"
    export gpu_max_limit
}

check_gpu_boost_freq () {
    [ -n "$GPU_BOOST_FREQ" ] && [ -f $GPU_BOOST_FREQ ]
}

read_gpu_boost_freq () {
    gpu_boost_freq=$(cat $GPU_BOOST_FREQ)
}

set_gpu_boost_freq () {
    gpuboostfreq=$1
    if [ -n "$gpuboostfreq" ] && [ "$gpuboostfreq" != "0" ]; then
        printf '%s\n' "$gpuboostfreq" > $GPU_BOOST_FREQ 2> /dev/null
    fi
    read_gpu_boost_freq
    json="{"
    json="${json}\"gpu_boost_freq\":\"${gpu_boost_freq}\""
    json="${json}}"
    echo "$json"
}

check_gpu_cur_freq () {
    [ -n "$GPU_CUR_FREQ" ] && [ -f $GPU_CUR_FREQ ]
}

read_gpu_cur_freq () {
    gpu_cur_freq="$(cat $GPU_CUR_FREQ)"
    export gpu_cur_freq
}

check_intel_tcc() {
    [ -n "${INTEL_TCC}" ] && [ -d "${INTEL_TCC}" ]
}

check_intel_tcc_cur_state() {
    [ -n "${INTEL_TCC}" ] && [ -d "${INTEL_TCC}" ]
}

read_intel_tcc_cur_state() {
    intel_tcc_cur_state=$(cat "${INTEL_TCC}/cur_state")
}

set_intel_tcc_cur_state() {
    printf "%s" "$1" > "${INTEL_TCC}/cur_state" 2> /dev/null
    read_intel_tcc_cur_state
    json="{"
    json="${json}\"intel_tcc_cur_state\":\"${intel_tcc_cur_state}\""
    json="${json}}"
    echo "$json"
}

check_intel_tcc_max_state() {
    [ -n "${INTEL_TCC}" ] && [ -d "${INTEL_TCC}" ]
}

read_intel_tcc_max_state() {
    intel_tcc_max_state="$(cat "${INTEL_TCC}"/max_state)"
    export intel_tcc_max_state
}

check_intel_rapl_short() {
    [ -n "${INTEL_RAPL}" ] && [ -f "${INTEL_RAPL_SHORT}" ]
}

read_intel_rapl_short() {
    intel_rapl_short=$(( $(cat "${INTEL_RAPL_SHORT}") / 1000000 ))
}

set_intel_rapl_short() {
    printf "%s" $(($1 * 1000000)) > "${INTEL_RAPL_SHORT}" 2> /dev/null
    printf "1" > "${INTEL_RAPL}/enabled" 2> /dev/null
    read_intel_rapl_short
    json="{"
    json="${json}\"intel_rapl_short\":\"${intel_rapl_short}\""
    json="${json}}"
    echo "$json"
}

check_intel_rapl_long() {
    [ -n "${INTEL_RAPL}" ] && [ -f "${INTEL_RAPL_LONG}" ]
}

read_intel_rapl_long() {
    intel_rapl_long=$(( $(cat "${INTEL_RAPL_LONG}") / 1000000 ))
}

set_intel_rapl_long() {
    printf "%s" "$(($1 * 1000000))" > "${INTEL_RAPL_LONG}" 2> /dev/null
    printf "1" > "${INTEL_RAPL}/enabled" 2> /dev/null
    read_intel_rapl_long
    json="{"
    json="${json}\"intel_rapl_long\":\"${intel_rapl_long}\""
    json="${json}}"
    echo "$json"
}
