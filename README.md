# Intel P-state and CPUFreq Manager Widget

```diff
-Important
```
as of October 11, 2020, I'm not willing to maintain this widget anymore. I will maintain it based only to my personal needs. I thank you for your support and feedback all this time. Hope the community will take over from here and make the widget even better than it is now. 

## What it is
Intel P-state and CPUFreq Manager is a KDE Plasma widget in order to control 
the frequencies of Intel CPUs and their integrated GPUs for any modern Intel 
Processors running in 
[Active Mode with HWP](https://www.kernel.org/doc/html/v4.12/admin-guide/pm/intel_pstate.html#active-mode-with-hwp) 
or 
[Active Mode Without HWP](https://www.kernel.org/doc/html/v4.12/admin-guide/pm/intel_pstate.html#active-mode-without-hwp). 
It can also manage the processor's energy consumption through Energy-Performance 
Preference (EPP) knob (if supported) or the Energy-Performance Bias (EPB) knob 
(otherwise).

<a target="_blank" rel="noopener noreferrer" href="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_1.png"><img src="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_1.png" alt="Intel P-state and CPUFreq Manager Widget" title="Intel P-state and CPUFreq Manager Widget" width="500px"></a>

Furthermore, it allows you to interact with the following vendor specific settings

1. [Dell's Thermal Management Feature](https://www.dell.com/support/manuals/ba/en/babsdt1/dell-command-power-manager-v2.2/userguide_dell/thermal-management?guid=guid-c05d2582-fc07-4e3e-918a-965836d20752&lang=en-us) 
through [libsmbios library](https://github.com/dell/libsmbios).

<a target="_blank" rel="noopener noreferrer" href="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_2.png"><img src="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_2.png" alt="Intel P-state and CPUFreq Manager Widget with Dell's Thermal Management Feature" title="Intel P-state and CPUFreq Manager Widget with Dell's Thermal Management Feature" width="500px"></a>

2. LG Gram laptop [Battery care limit](https://github.com/torvalds/linux/blob/master/Documentation/laptops/lg-laptop.rst#battery-care-limit), [USB charge](https://github.com/torvalds/linux/blob/master/Documentation/laptops/lg-laptop.rst#usb-charge) and [Fan mode](https://github.com/torvalds/linux/blob/master/Documentation/laptops/lg-laptop.rst#fan-mode) features (on kernel 4.20 and higher).

<a target="_blank" rel="noopener noreferrer" href="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_3.png"><img src="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_3.png" alt="Intel P-state and CPUFreq Manager Widget with LG Laptop Support features" title="Intel P-state and CPUFreq Manager Widget with LG Laptop Support features" width="500px"></a>

3. [Nvidia PowerMizer Settings](https://www.nvidia.com/object/feature_powermizer.html). 

<a target="_blank" rel="noopener noreferrer" href="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_4.png"><img src="https://github.com/jsalatas/plasma-pstate/raw/master/screenshots/screenshot_4.png" alt="Intel P-state and CPUFreq Manager Widget with Nvidia PowerMizer Settings" title="Intel P-state and CPUFreq Manager Widget with Nvidia PowerMizer Settings" width="500px"></a>


## What it isn't
This is just a GUI widget and it is not meant to replace 
[TLP](https://linrunner.de/en/tlp/tlp.html), [powertop](https://01.org/powertop) or 
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

Under blackPanther OS just run
```
installing plasma-pstate

```

From source You can just clone 
the code and install it using the following commands:

```
git clone https://github.com/jsalatas/plasma-pstate
cd plasma-pstate
./install.sh
```
**Notice:** If your processor doesn't support EPP(ie older generations without 
HWP), then you need also to install the ``x86_energy_perf_policy`` which is 
provided by the ``kernel-tools`` (in case of Ubuntu 18.04 distros) ``linux-tools`` package and 
can be installed using the following command

```
installing kernel-tools
```

or on another Debian based distro

```
sudo apt install linux-tools-generic linux-tools-`uname -r`
```
## How to update
Assuming that you have checked out the latest code, you just need to run the following commands as root:

```
kpackagetool5 -g -t Plasma/Applet -u gr.ictpro.jsalatas.plasma.pstate

chmod 755 /usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh 
```

## Contributions
Please feel free to clone, hack, and contribute anything you may find useful, 
especially in relation to similar to Dell's Thermal Management Feature that 
may be available in other hardware platforms.

