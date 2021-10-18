# Intel P-state and CPUFreq Manager Widget

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

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_1.png"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_1.png" alt="Intel P-state and CPUFreq Manager Widget" title="Intel P-state and CPUFreq Manager Widget" width="500px"></a>

Furthermore, it allows you to interact with the following vendor specific settings

1. [Dell's Thermal Management Feature](https://www.dell.com/support/manuals/ba/en/babsdt1/dell-command-power-manager-v2.2/userguide_dell/thermal-management?guid=guid-c05d2582-fc07-4e3e-918a-965836d20752&lang=en-us) 
through [libsmbios library](https://github.com/dell/libsmbios).

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_2.png"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_2.png" alt="Intel P-state and CPUFreq Manager Widget with Dell's Thermal Management Feature" title="Intel P-state and CPUFreq Manager Widget with Dell's Thermal Management Feature" width="500px"></a>

2. LG Gram laptop [Battery care limit](https://github.com/torvalds/linux/blob/master/Documentation/laptops/lg-laptop.rst#battery-care-limit), [USB charge](https://github.com/torvalds/linux/blob/master/Documentation/laptops/lg-laptop.rst#usb-charge) and [Fan mode](https://github.com/torvalds/linux/blob/master/Documentation/laptops/lg-laptop.rst#fan-mode) features (on kernel 4.20 and higher).

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/screenshot_3.png"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/screenshot_3.png" alt="Intel P-state and CPUFreq Manager Widget with LG Laptop Support features" title="Intel P-state and CPUFreq Manager Widget with LG Laptop Support features" width="500px"></a>

3. [Nvidia PowerMizer Settings](https://www.nvidia.com/object/feature_powermizer.html). 

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_4.png"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_4.png" alt="Intel P-state and CPUFreq Manager Widget with Nvidia PowerMizer Settings" title="Intel P-state and CPUFreq Manager Widget with Nvidia PowerMizer Settings" width="500px"></a>


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
First of all you need to be in sudoers' group. After that you can just clone 
the code and install it using the following commands:

```
git clone https://github.com/frankenfruity/plasma-pstate
cd plasma-pstate
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_BUILD_TYPE=Release ..
make
make install

cd ..
cp ./src/plasma_pstate.policy /usr/share/polkit-1/actions/
chmod 644 /usr/share/polkit-1/actions/plasma_pstate.policy
```

**Notice:** If your processor doesn't support EPP(ie older generations without 
HWP), then you need also to install the ``x86_energy_perf_policy`` which (in 
case of Ubuntu 18.04 distros) is provided by the ``linux-tools`` package and 
can be installed using the following command

```
sudo apt install linux-tools-generic linux-tools-`uname -r`
```

## Custom profiles

A profile applies multiple settings at once.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5a.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5a.jpg"></a>

Click the Edit profiles button to manage profiles.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5b.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5b.jpg"></a>

In edit mode, use the toolbar buttons to create or delete a profile.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5c.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5c.jpg"></a>

Edit a profile name in the text box.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5d.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5d.jpg"></a>

Select the settings to be included in a profile.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5f.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5f.jpg"></a>

Colors of the navigation bar are inverted in edit mode. The config menus modify the values of the current profile.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5e.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5e.jpg"></a>

Save or discard changes to exit edit mode.

<a target="_blank" rel="noopener noreferrer" href="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5g.jpg"><img src="https://github.com/frankenfruity/plasma-pstate/raw/master/screenshots/Screenshot_5g.jpg"></a>

## Contributions
Please feel free to clone, hack, and contribute anything you may find useful, 
especially in relation to similar to Dell's Thermal Management Feature that 
may be available in other hardware platforms.
