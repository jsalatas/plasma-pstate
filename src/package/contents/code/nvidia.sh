#!/bin/bash


NV_PCI_DEV=$(grep -H 0x10de /sys/class/drm/card?/device/vendor 2>/dev/null | \
             head -n1 | sed 's/\/vendor:.*//')
NV_RUNTIME_STATUS=${NV_PCI_DEV}/power/runtime_status

check_powermizer () {
    # nvidia-settings -q GpuPowerMizerMode > /dev/null 2>&1
    # OUT=$?
    # if [ $OUT -eq 0 ]; then
    #     return 0
    # else
    #     return 1
    # fi
    return 1
}

read_powermizer() {
    powermizer="0"
    export powermizer
}

set_powermizer () {
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=$1" > /dev/null
    echo "{}"
}

check_nvidia_runtime_status() {
    [ -n "${NV_PCI_DEV}" ] && [ -f "${NV_RUNTIME_STATUS}" ]
}

read_nvidia_runtime_status() {
    nvidia_runtime_status=$(cat "${NV_RUNTIME_STATUS}")
    export nvidia_runtime_status
}

set_nvidia_runtime_status() {
    echo "{}"
}
