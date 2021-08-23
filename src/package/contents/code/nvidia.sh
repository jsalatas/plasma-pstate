#!/bin/bash

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
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=$1" 2> /dev/null
    echo "{}"
}
