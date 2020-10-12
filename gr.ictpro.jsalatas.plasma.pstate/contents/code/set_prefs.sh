#!/bin/bash

INTEL_PSTATE=/sys/devices/system/cpu/intel_pstate
CPU_MIN_PERF=$INTEL_PSTATE/min_perf_pct
CPU_MAX_PERF=$INTEL_PSTATE/max_perf_pct
CPU_TURBO=$INTEL_PSTATE/no_turbo

GPU=/sys/class/drm/card0
GPU_MIN_FREQ=$GPU/gt_min_freq_mhz
GPU_MAX_FREQ=$GPU/gt_max_freq_mhz
GPU_MIN_LIMIT=$GPU/gt_RP1_freq_mhz
GPU_MAX_LIMIT=$GPU/gt_RP0_freq_mhz
GPU_BOOST_FREQ=$GPU/gt_boost_freq_mhz
GPU_CUR_FREQ=$GPU/gt_cur_freq_mhz

LG_LAPTOP_DRIVER=/sys/devices/platform/lg-laptop
LG_FAN_MODE=$LG_LAPTOP_DRIVER/fan_mode
LG_BATTERY_CHARGE_LIMIT=$LG_LAPTOP_DRIVER/battery_care_limit
LG_USB_CHARGE=$LG_LAPTOP_DRIVER/usb_charge

check_lg_drivers() {
    if [ -d $LG_LAPTOP_DRIVER ]; then
        return 0
    else
        return 1
    fi
}

check_dell_thermal () {
    smbios-thermal-ctl -g > /dev/null 2>&1
    OUT=$?
    if [ $OUT -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

check_nvidia () {
    nvidia-settings -q GpuPowerMizerMode > /dev/null 2>&1
    OUT=$?
    if [ $OUT -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

read_cpu_min_perf () {
    cpu_min_perf=`cat $CPU_MIN_PERF`
}

set_cpu_min_perf () {
    minperf=$1
    if [ -n "$minperf" ] && [ "$minperf" != "0" ]; then
        printf '%s\n' "$minperf" > $CPU_MIN_PERF; 2> /dev/null
    fi
    read_cpu_min_perf
    json="{"
    json="${json}\"cpu_min_perf\":\"${cpu_min_perf}\""
    json="${json}}"
    echo $json
}

read_cpu_max_perf () {
    cpu_max_perf=`cat $CPU_MAX_PERF`
}

set_cpu_max_perf () {
    maxperf=$1
    if [ -n "$maxperf" ] && [ "$maxperf" != "0" ]; then
        printf '%s\n' "$maxperf" > $CPU_MAX_PERF; 2> /dev/null
    fi
    read_cpu_max_perf
    json="{"
    json="${json}\"cpu_max_perf\":\"${cpu_max_perf}\""
    json="${json}}"
    echo $json
}

read_cpu_turbo () {
    cpu_turbo=`cat $CPU_TURBO`
    if [ "$cpu_turbo" == "1" ]; then
        cpu_turbo="false"
    else
        cpu_turbo="true"
    fi
}

set_cpu_turbo () {
    turbo=$1
    if [ -n "$turbo" ]; then
        if [ "$turbo" == "true" ]; then
            printf '0\n' > $CPU_TURBO; 2> /dev/null
        else
            printf '1\n' > $CPU_TURBO; 2> /dev/null
        fi
    fi
    read_cpu_turbo
    json="{"
    json="${json}\"cpu_turbo\":\"${cpu_turbo}\""
    json="${json}}"
    echo $json
}

read_gpu_min_freq () {
    gpu_min_freq=`cat $GPU_MIN_FREQ`
}

set_gpu_min_freq () {
    gpuminfreq=$1
    if [ -n "$gpuminfreq" ] && [ "$gpuminfreq" != "0" ]; then
        printf '%s\n' "$gpuminfreq" > $GPU_MIN_FREQ; 2> /dev/null
    fi
    read_gpu_min_freq
    json="{"
    json="${json}\"gpu_min_freq\":\"${gpu_min_freq}\""
    json="${json}}"
    echo $json
}

read_gpu_max_freq () {
    gpu_max_freq=`cat $GPU_MAX_FREQ`
}

set_gpu_max_freq () {
    gpumaxfreq=$1
    if [ -n "$gpumaxfreq" ] && [ "$gpumaxfreq" != "0" ]; then
        printf '%s\n' "$gpumaxfreq" > $GPU_MAX_FREQ; 2> /dev/null
    fi
    read_gpu_max_freq
    json="{"
    json="${json}\"gpu_max_freq\":\"${gpu_max_freq}\""
    json="${json}}"
    echo $json
}

read_gpu_boost_freq () {
    gpu_boost_freq=`cat $GPU_BOOST_FREQ`
}

set_gpu_boost_freq () {
    gpuboostfreq=$1
    if [ -n "$gpuboostfreq" ] && [ "$gpuboostfreq" != "0" ]; then
        printf '%s\n' "$gpuboostfreq" > $GPU_BOOST_FREQ; 2> /dev/null
    fi
    read_gpu_boost_freq
    json="{"
    json="${json}\"gpu_boost_freq\":\"${gpu_boost_freq}\""
    json="${json}}"
    echo $json
}

read_cpu_governor () {
    cpu_governor=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
}

set_cpu_governor () {
    gov=$1
    if [ -n "$gov" ]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            printf '%s\n' "$gov" > $cpu; 2> /dev/null
        done
    fi
    read_cpu_governor
    json="{"
    json="${json}\"cpu_governor\":\"${cpu_governor}\""
    json="${json}}"
    echo $json
}

read_energy_perf () {
    energy_perf=`cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null`
    if [ -z "$energy_perf" ]; then
        energy_perf=`x86_energy_perf_policy -r 2>/dev/null | grep -v 'HWP_' | \
        sed -r 's/://;
                s/(0x0000000000000000|EPB 0)/performance/;
                s/(0x0000000000000004|EPB 4)/balance_performance/;
                s/(0x0000000000000006|EPB 6)/default/;
                s/(0x0000000000000008|EPB 8)/balance_power/;
                s/(0x000000000000000f|EPB 15)/power/' | \
        awk '{ printf "%s\n", $2; }' | head -n 1`
    fi
}

set_energy_perf () {
    energyperf=$1
    if [ -n "$energyperf" ]; then
        if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
                printf '%s\n' "$energyperf" > $cpu; 2> /dev/null
            done
        else
            pnum=$(echo $energyperf | sed -r 's/^performance$/0/;
                                s/^balance_performance$/4/;
                                s/^(default|normal)$/6/;
                                s/^balance_power?$/8/;
                                s/^power(save)?$/15/')

            x86_energy_perf_policy $pnum > /dev/null 2>&1
        fi
    fi
    read_energy_perf
    json="{"
    json="${json}\"energy_perf\":\"${energy_perf}\""
    json="${json}}"
    echo $json
}

set_lg_battery_charge_limit(){
    enabled=$1
    if [ -n "$enabled" ]; then
        if [ "$enabled" == "true" ]; then
            printf '80\n' > $LG_BATTERY_CHARGE_LIMIT; 2> /dev/null
        else
            printf '100\n' > $LG_BATTERY_CHARGE_LIMIT; 2> /dev/null
        fi
    fi
}

set_lg_fan_mode() {
    enabled=$1
    if [ -n "$enabled" ]; then
        if [ "$enabled" == "true" ]; then
           printf '0\n' > $LG_FAN_MODE; 2> /dev/null
        else
           printf '1\n' > $LG_FAN_MODE; 2> /dev/null
        fi
    fi
}

set_powermizer () {
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=$1" 2> /dev/null
}

set_lg_usb_charge()  {
    enabled=$1
    if [ -n "$enabled" ]; then
        if [ "$enabled" == "true" ]; then
           printf '1\n' > $LG_USB_CHARGE; 2> /dev/null
        else
           printf '0\n' > $LG_USB_CHARGE; 2> /dev/null
        fi
    fi
}

read_thermal_mode () {
    thermal_mode=`smbios-thermal-ctl -g | grep -C 1 "Current Thermal Modes:"  | tail -n 1 | awk '{$1=$1;print}' | sed "s/\t//g" | sed "s/ /-/g" | tr [A-Z] [a-z] `
}

set_thermal_mode () {
    smbios-thermal-ctl --set-thermal-mode=$1 > /dev/null 2>&1
    read_thermal_mode
    json="{"
    json="${json}\"thermal_mode\":\"${thermal_mode}\""
    json="${json}}"
    echo $json
}

read_all () {
read_cpu_min_perf
read_cpu_max_perf

read_cpu_turbo

gpu_min_limit=`cat $GPU_MIN_LIMIT`
gpu_max_limit=`cat $GPU_MAX_LIMIT`
gpu_cur_freq=`cat $GPU_CUR_FREQ`
read_gpu_min_freq
read_gpu_max_freq
read_gpu_boost_freq
read_cpu_governor
read_energy_perf

if check_lg_drivers; then
    lg_battery_charge_limit=`cat $LG_BATTERY_CHARGE_LIMIT`
    if [ "$lg_battery_charge_limit" == "80" ]; then
        lg_battery_charge_limit="true"
    else
        lg_battery_charge_limit="false"
    fi
    lg_usb_charge=`cat $LG_USB_CHARGE`
    if [ "$lg_usb_charge" == "1" ]; then
        lg_usb_charge="true"
    else
        lg_usb_charge="false"
    fi
    lg_fan_mode=`cat $LG_FAN_MODE`
    if [ "$lg_fan_mode" == "1" ]; then
        lg_fan_mode="false"
    else
        lg_fan_mode="true"
    fi
fi

if check_nvidia; then
    powermizer=`nvidia-settings -q GpuPowerMizerMode | grep "Attribute 'GPUPowerMizerMode'" | awk -F "): " '{print $2}'  | awk -F "." '{print $1}' ` 
fi

json="{"
json="${json}\"cpu_min_perf\":\"${cpu_min_perf}\""
json="${json},\"cpu_max_perf\":\"${cpu_max_perf}\""
json="${json},\"cpu_turbo\":\"${cpu_turbo}\""
json="${json},\"gpu_min_freq\":\"${gpu_min_freq}\""
json="${json},\"gpu_max_freq\":\"${gpu_max_freq}\""
json="${json},\"gpu_min_limit\":\"${gpu_min_limit}\""
json="${json},\"gpu_max_limit\":\"${gpu_max_limit}\""
json="${json},\"gpu_boost_freq\":\"${gpu_boost_freq}\""
json="${json},\"gpu_cur_freq\":\"${gpu_cur_freq}\""
json="${json},\"cpu_governor\":\"${cpu_governor}\""
json="${json},\"energy_perf\":\"${energy_perf}\""
if check_dell_thermal; then
    read_thermal_mode
    json="${json},\"thermal_mode\":\"${thermal_mode}\""
fi
if check_lg_drivers; then
    json="${json},\"lg_battery_charge_limit\":\"${lg_battery_charge_limit}\""
    json="${json},\"lg_usb_charge\":\"${lg_usb_charge}\""
    json="${json},\"lg_fan_mode\":\"${lg_fan_mode}\""
fi
if check_nvidia; then
    json="${json},\"powermizer\":\"${powermizer}\""
fi
json="${json}}"
echo $json
}

case $1 in
    "cpu-min-perf")
        set_cpu_min_perf $2
        ;;

    "cpu-max-perf")
        set_cpu_max_perf $2
        ;;

    "cpu-turbo")
        set_cpu_turbo $2
        ;;

    "gpu-min-freq")
        set_gpu_min_freq $2
        ;;

    "gpu-max-freq")
        set_gpu_max_freq $2
        ;;

    "gpu-boost-freq")
        set_gpu_boost_freq $2
        ;;

    "cpu-governor")
        set_cpu_governor $2
        ;;

    "energy-perf")
        set_energy_perf $2
        ;;

    "thermal-mode")
        set_thermal_mode $2
        ;;

    "lg-battery-charge-limit")
	set_lg_battery_charge_limit $2
	;;

    "lg-fan-mode")
	set_lg_fan_mode $2
	;;

    "lg-usb-charge")
	set_lg_usb_charge $2
	;;

    "powermizer")
        set_powermizer $2
        ;;

    "read-all")
        read_all
        ;;

    *)
        echo "Usage:"
        echo "1: set_prefs.sh [ cpu-min-perf |"
        echo "                  cpu-max-perf |"
        echo "                  cpu-turbo |"
        echo "                  gpu-min-freq |"
        echo "                  gpu-max-freq |"
        echo "                  gpu-boost-freq |"
        echo "                  cpu-governor |"
        echo "                  energy-perf |"
        echo "                  thermal-mode ] value"
        echo "                  lg-battery-charge-limit |"
        echo "                  lg-fan-mode |"
        echo "                  lg-usb-charge |"
        echo "                  powermizer ] value"
        echo "2: set_prefs.sh   read-all"
        exit 3
        ;;

esac
