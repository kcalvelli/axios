#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
#
# axiOS hardware auto-detection job module
#
# Runs before the show phase to populate globalstorage with detected
# hardware values. The axiosconfig QML page reads these as defaults.

import glob
import os
import subprocess

import libcalamares


def detect_cpu():
    """Detect CPU vendor from /proc/cpuinfo."""
    try:
        with open("/proc/cpuinfo", "r") as f:
            content = f.read()
        if "GenuineIntel" in content:
            return "intel"
        elif "AuthenticAMD" in content:
            return "amd"
    except OSError:
        pass
    return ""


def detect_gpu():
    """Detect GPU vendor from lspci VGA output."""
    try:
        result = subprocess.run(
            ["lspci"], capture_output=True, text=True, timeout=10
        )
        for line in result.stdout.splitlines():
            lower = line.lower()
            if "vga" not in lower and "3d" not in lower:
                continue
            if "nvidia" in lower:
                return "nvidia"
            elif "amd" in lower or "ati" in lower:
                return "amd"
            elif "intel" in lower:
                return "intel"
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return ""


def detect_form_factor():
    """Detect form factor from battery presence."""
    # Check for BAT* entries in power_supply
    bat_paths = glob.glob("/sys/class/power_supply/BAT*")
    if bat_paths:
        return "laptop"

    # Also check for a generic "battery" entry
    if os.path.isdir("/sys/class/power_supply/battery"):
        return "laptop"

    return "desktop"


def detect_ssd():
    """Detect SSD presence from block device rotational flag."""
    try:
        for entry in os.listdir("/sys/block"):
            rotational_path = "/sys/block/{}/queue/rotational".format(entry)
            if os.path.exists(rotational_path):
                with open(rotational_path, "r") as f:
                    if f.read().strip() == "0":
                        return True
    except OSError:
        pass
    return False


def run():
    """Main Calamares job entry point."""
    gs = libcalamares.globalstorage

    cpu = detect_cpu()
    gpu = detect_gpu()
    form_factor = detect_form_factor()
    has_ssd = detect_ssd()

    if cpu:
        gs.insert("axios_cpuVendor", cpu)
    if gpu:
        gs.insert("axios_gpuVendor", gpu)

    gs.insert("axios_formFactor", form_factor)
    gs.insert("axios_hasSSD", has_ssd)

    libcalamares.utils.debug(
        "axiosdetect: cpu={}, gpu={}, formFactor={}, hasSSD={}".format(
            cpu or "unknown", gpu or "unknown", form_factor, has_ssd
        )
    )

    return None
