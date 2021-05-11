#!/usr/bin/env bash

ACPI_CPU=/sys/devices/system/cpu
if [ -d /sys/devices/system/cpu/cpufreq ]; then
  INTEL_PSTATE=$ACPI_CPU/cpufreq
  CPU_MIN_PERF=$INTEL_PSTATE/policy0/scaling_min_freq
  CPU_MAX_PERF=$INTEL_PSTATE/policy0/scaling_max_freq
  CPU_MIN_PERF_SET=$INTEL_PSTATE/policy*/scaling_min_freq
  CPU_MAX_PERF_SET=$INTEL_PSTATE/policy*/scaling_max_freq
  CPU_MIN_FREQ=$INTEL_PSTATE/policy0/cpuinfo_min_freq
  CPU_MAX_FREQ=$INTEL_PSTATE/policy0/cpuinfo_max_freq
  CPU_TURBO=$INTEL_PSTATE/boost
  AMD=1
else
  INTEL_PSTATE=$ACPI_CPU/intel_pstate
  CPU_MIN_PERF=$INTEL_PSTATE/min_perf_pct
  CPU_MAX_PERF=$INTEL_PSTATE/max_perf_pct
  CPU_TURBO=$INTEL_PSTATE/no_turbo
  AMD=0
fi
CPU_TOTAL_AVAILABLE=$(nproc --all)
CPU_ONLINE=$(nproc)

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
    /usr/bin/pkexec /usr/share/plasma/plasmoids/org.thefreecircle.mibofra.plasma.pstate/contents/code/get_thermal.sh > /dev/null 2>&1
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

check_isw () {
    isw=`command -v isw`
    if [ -z "${isw}" ]; then
        return 1
    else
        return 0
    fi
}

set_cpu_min_perf () {
    minperf=$1
    if [ -n "$minperf" ] && [ "$minperf" != "0" -a "$AMD" == "0" -o "$AMD" == "1" ]; then
      if [ "$AMD" == "0" ]; then
        printf '%s\n' "$minperf" > $CPU_MIN_PERF; 2> /dev/null
      else
        minfreq=$(cat $CPU_MIN_FREQ)
        maxfreq=$(cat $CPU_MAX_FREQ)
        freq=$((($maxfreq-$minfreq)*$minperf/100 + $minfreq))
        for d in $CPU_MIN_PERF_SET; do 
          printf '%s\n' "$freq" > $d; 2> /dev/null
        done
      fi
    fi
}

set_cpu_max_perf () {
    maxperf=$1
    if [ -n "$maxperf" ] && [ "$maxperf" != "0" ]; then
      if [ "$AMD" == "0" ]; then
        printf '%s\n' "$maxperf" > $CPU_MAX_PERF; 2> /dev/null
      else
        minfreq=$(cat $CPU_MIN_FREQ)
        maxfreq=$(cat $CPU_MAX_FREQ)
        freq=$((($maxfreq-$minfreq)*$maxperf/100 + $minfreq))
        for d in $CPU_MAX_PERF_SET; do 
          printf '%s\n' "$freq" > $d; 2> /dev/null
        done
      fi
    fi
}

set_cpu_turbo () {
    turbo=$1
    if [ -n "$turbo" ]; then
        if [ "$turbo" == "true" ]; then
          if [ "$AMD" == "0" ]; then
            printf '0\n' > $CPU_TURBO; 2> /dev/null
          else
            printf '1\n' > $CPU_TURBO; 2> /dev/null
          fi
        else
          if [ "$AMD" == "0" ]; then
            printf '1\n' > $CPU_TURBO; 2> /dev/null
          else
            printf '0\n' > $CPU_TURBO; 2> /dev/null
          fi
        fi
    fi
}

set_cpu_state () {
    num=$1
    num_off=$[$CPU_TOTAL_AVAILABLE-$num]
    counter=1
    limit=$[$num-1]
    all_off=$[$CPU_TOTAL_AVAILABLE-1]
    if [ -n "$num" ] && [ "$num" != "0" ]; then
        if [ "$num" -ne "1" ]; then
            while [ "$counter" -le "$limit" ]; do
                    printf '1\n' > $ACPI_CPU/cpu$counter/online; 2> /dev/null
                    counter=$[$counter+1]
            done
            limit=$[$limit+$num_off]
            while [ "$counter" -le "$limit" ]; do
                    printf '0\n' > $ACPI_CPU/cpu$counter/online; 2> /dev/null
                    counter=$[$counter+1]
            done
        else
            while [ "$counter" -le "$all_off" ]; do
                    printf '0\n' > $ACPI_CPU/cpu$counter/online; 2> /dev/null
                    counter=$[$counter+1]
            done
        fi    
    fi
}

set_gpu_min_freq () {
    gpuminfreq=$1
    if [ -n "$gpuminfreq" ] && [ "$gpuminfreq" != "0" ]; then
        printf '%s\n' "$gpuminfreq" > $GPU_MIN_FREQ; 2> /dev/null
    fi
}

set_gpu_max_freq () {
    gpumaxfreq=$1
    if [ -n "$gpumaxfreq" ] && [ "$gpumaxfreq" != "0" ]; then
        printf '%s\n' "$gpumaxfreq" > $GPU_MAX_FREQ; 2> /dev/null
    fi
}

set_gpu_boost_freq () {
    gpuboostfreq=$1
    if [ -n "$gpuboostfreq" ] && [ "$gpuboostfreq" != "0" ]; then
        printf '%s\n' "$gpuboostfreq" > $GPU_BOOST_FREQ; 2> /dev/null
    fi
}

set_cpu_governor () {
    gov=$1
    if [ -n "$gov" ]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            printf '%s\n' "$gov" > $cpu; 2> /dev/null
        done
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
}

set_thermal_mode () {
    smbios-thermal-ctl --set-thermal-mode=$1 2> /dev/null
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
           printf '0' > $LG_FAN_MODE; 2> /dev/null
        else
           printf '1' > $LG_FAN_MODE; 2> /dev/null
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

set_cooler_boost () {
    boost=$1
    if [ -n "$boost" ]; then
        if [ "$boost" == "true" ]; then
            printf '1\n' > /run/isw_cooler_boost; 2> /dev/null
            isw -b on; 2> /dev/null
        else
            printf '0\n' > /run/isw_cooler_boost; 2> /dev/null
            isw -b off; 2> /dev/null
        fi
    fi
}

read_all () {
if [ "$AMD" == "0" ]; then
  cpu_min_perf=`cat $CPU_MIN_PERF`
  cpu_max_perf=`cat $CPU_MAX_PERF`
else
  cpu_min_freq=`cat $CPU_MIN_FREQ`
  cpu_max_freq=`cat $CPU_MAX_FREQ`
  max=$(cat $CPU_MAX_PERF)
  min=$(cat $CPU_MIN_PERF)
  cpu_max_perf=$(((100+($max-$cpu_max_freq)*100/$cpu_max_freq)))
  cpu_min_perf=$((($min-$cpu_min_freq)*100/$cpu_min_freq))
fi
cpu_total_available=`echo $CPU_TOTAL_AVAILABLE`
cpu_online=`echo $CPU_ONLINE`
cpu_turbo=`cat $CPU_TURBO`
if [ "$cpu_turbo" == "1" -a "$AMD" = "0" -o "$cpu_turbo" == "0" -a "$AMD" = "1" ]; then
    cpu_turbo="false"
else
    cpu_turbo="true"
fi
if [ -f $GPU_MIN_FREQ ]; then
    gpu_min_freq=`cat $GPU_MIN_FREQ`
    gpu_max_freq=`cat $GPU_MAX_FREQ`
    gpu_min_limit=`cat $GPU_MIN_LIMIT`
    gpu_max_limit=`cat $GPU_MAX_LIMIT`
    gpu_boost_freq=`cat $GPU_BOOST_FREQ`
    gpu_cur_freq=`cat $GPU_CUR_FREQ`
fi
cpu_governor=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
energy_perf=`cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference`
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
if check_dell_thermal; then
    thermal_mode=`/usr/bin/pkexec /usr/share/plasma/plasmoids/org.thefreecircle.mibofra.plasma.pstate/contents/code/get_thermal.sh | grep -C 1 "Current Thermal Modes:"  | tail -n 1 | awk '{$1=$1;print}' | sed "s/\t//g" | sed "s/ /-/g" | tr "[A-Z]" "[a-z]" `
fi

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
    powermizer=`nvidia-settings -q GpuPowerMizerMode 2> /dev/null | grep "Attribute 'GPUPowerMizerMode'" | awk -F "): " '{print $2}'  | awk -F "." '{print $1}' ` 
fi

if check_isw; then
    if [[ ! -f /run/isw_cooler_boost ]]; then
        cooler_boost="false"
    else 
        cooler_boost=`cat /run/isw_cooler_boost`
        if [ "$cooler_boost" == "1" ]; then
            cooler_boost="true"
        else
            cooler_boost="false"
        fi
    fi
fi

json="{"
json="${json}\"cpu_min_perf\":\"${cpu_min_perf}\""
json="${json},\"cpu_max_perf\":\"${cpu_max_perf}\""
json="${json},\"cpu_turbo\":\"${cpu_turbo}\""
json="${json},\"cpu_total_available\":\"${cpu_total_available}\""
json="${json},\"cpu_online\":\"${cpu_online}\""
if [ -f $GPU_MIN_FREQ ]; then
    json="${json},\"gpu_min_freq\":\"${gpu_min_freq}\""
    json="${json},\"gpu_max_freq\":\"${gpu_max_freq}\""
    json="${json},\"gpu_min_limit\":\"${gpu_min_limit}\""
    json="${json},\"gpu_max_limit\":\"${gpu_max_limit}\""
    json="${json},\"gpu_boost_freq\":\"${gpu_boost_freq}\""
    json="${json},\"gpu_cur_freq\":\"${gpu_cur_freq}\""
fi
json="${json},\"cpu_governor\":\"${cpu_governor}\""
json="${json},\"energy_perf\":\"${energy_perf}\""
if check_dell_thermal; then
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
if check_isw; then
    json="${json},\"cooler_boost\":\"${cooler_boost}\""
fi
json="${json}}"
echo $json
}

case $1 in
    "-cpu-min-perf")
        set_cpu_min_perf $2
        ;;

    "-cpu-max-perf")
        set_cpu_max_perf $2
        ;;

    "-cpu-turbo")
        set_cpu_turbo $2
        ;;

    "-cpu-online")
        set_cpu_state $2
        ;;

    "-gpu-min-freq")
        set_gpu_min_freq $2
        ;;

    "-gpu-max-freq")
        set_gpu_max_freq $2
        ;;

    "-gpu-boost-freq")
        set_gpu_boost_freq $2
        ;;

    "-cpu-governor")
        set_cpu_governor $2
        ;;

    "-energy-perf")
        set_energy_perf $2
        ;;

    "-thermal-mode")
        set_thermal_mode $2
        ;;

    "-lg-battery-charge-limit")
	set_lg_battery_charge_limit $2
	;;

    "-lg-fan-mode")
	set_lg_fan_mode $2
	;;

    "-lg-usb-charge")
	set_lg_usb_charge $2
	;;

    "-powermizer")
        set_powermizer $2
        ;;

    "-cooler-boost")
        set_cooler_boost $2
        ;;

    "-read-all")
        read_all
        ;;

    *)
        echo "Usage:"
        echo "1: set_prefs.sh [ -cpu-min-perf |"
        echo "                  -cpu-max-perf |"
        echo "                  -cpu-turbo |"
        echo "                  -cpu-online |"
        echo "                  -gpu-min-freq |"
        echo "                  -gpu-max-freq |"
        echo "                  -gpu-boost-freq |"
        echo "                  -cpu-governor |"
        echo "                  -energy-perf |"
        echo "                  -thermal-mode |"
        echo "                  -lg-battery-charge-limit |"
        echo "                  -lg-fan-mode |"
        echo "                  -lg-usb-charge |"
        echo "                  -powermizer |"
        echo "                  -cooler-boost ] value"
        echo "2: set_prefs.sh -read-all"
        exit 3
        ;;
esac
