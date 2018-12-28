# Intel P-state and CPUFreq Manager Widget

## What it is
Intel P-state and CPUFreq Manager is a KDE Plasma widget in order to control 
the frequencies and energy consumption of Intel CPUs and their integrated 
GPUs for any modern Intel Processors running in [Active Mode with HWP](https://www.kernel.org/doc/html/v4.12/admin-guide/pm/intel_pstate.html#active-mode-with-hwp). 

![Intel P-state and CPUFreq Manager Widget](https://github.com/jsalatas/plasma-pstate/raw/master/screenshot_1.png "Intel P-state and CPUFreq Manager Widget")

Furthermore, if the hardware supports it, it allows you to interact with 
[Dell's Thermal Management Feature](https://www.dell.com/support/manuals/ba/en/babsdt1/dell-command-power-manager-v2.2/userguide_dell/thermal-management?guid=guid-c05d2582-fc07-4e3e-918a-965836d20752&lang=en-us) through [libsmbios library](https://github.com/dell/libsmbios).

![Intel P-state and CPUFreq Manager Widget with Dell's Thermal Management Feature](https://github.com/jsalatas/plasma-pstate/raw/master/screenshot_2.png "Intel P-state and CPUFreq Manager Widget with Dell's Thermal Management Feature")

## What it isn't
This is just a GUI widget and it is not meant to replace [TLP](https://linrunner.de/en/tlp/tlp.html), [powertop](https://01.org/powertop) or 
any other power management / energy consumption service. It is meant just to 
provide quick access to ``sysfs`` settings related to Intel Processors and 
in fact it can run on top of TLP.

## Why
As the trend in modern laptops continues to be more CPU power in more slim 
chassis design and as the software and becomes more demanding, it is becoming 
harder to find a combination of power performance and/or energy consumption 
settings to fit all your daily tasks that require different levels of 
performance. 

This widget's purpose is to expose to the user hardware and kernel settings
that may be useful in cases you need to adjust such a setting from the 
comfort of your graphical interface using point and click or tap interactions 
even in cases that a keyboard isn't available.

## How to install
First of all you need to be in sudoers' group. 

```
git clone https://github.com/jsalatas/plasma-pstate
cd plasma-pstate
sudo ./install.sh
```
## Contributions
Please feel free to clone, hack, and contribute anything you may find useful, 
especially in relation to similar to Dell's Thermal Management Feature that 
may be available in other hardware platforms.

## Systems known to work
- Dell XPS 15 9570



