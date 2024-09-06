#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# This script is a simple wrapper which prefixes each i3status line with custom
# information. It is a python reimplementation of:
# http://code.stapelberg.de/git/i3status/tree/contrib/wrapper.pl
#
# To use it, ensure your ~/.i3status.conf contains this line:
#     output_format = "i3bar"
# in the 'general' section.
# Then, in your ~/.i3/config, use:
#     status_command i3status | ~/i3status/contrib/wrapper.py
# In the 'bar' section.
#
# In its current version it will display the cpu frequency governor, but you
# are free to change it to display whatever you like, see the comment in the
# source code below.
#
# © 2012 Valentin Haenel <valentin.haenel@gmx.de>
#
# This program is free software. It comes without any warranty, to the extent
# permitted by applicable law. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public License (WTFPL), Version
# 2, as published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING for more
# details.
import glob
import json
import logging
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

import requests

logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)


def get_governor():
    """Get the current governor for cpu0, assuming all CPUs use the same."""
    with open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor") as fp:
        return fp.readlines()[0].strip()


def get_idletime() -> int:
    try:
        p = subprocess.run("xprintidle", capture_output=True)
    except FileNotFoundError:
        return 666 * 24 * 60 * 60
    return int(round(int(str(p.stdout, "ascii").strip()) / 1000))


def get_screen_brightness() -> Optional[int]:
    try:
        with open("/sys/class/backlight/intel_backlight/max_brightness", "r") as f:
            max_brightness = int(f.read())
        with open("/sys/class/backlight/intel_backlight/brightness", "r") as f:
            brightness = float(f.read())
        return int(brightness / max_brightness * 100)
    except FileNotFoundError:
        return None


def get_ram_usage() -> float:
    with open("/proc/meminfo", "r") as f:
        s = f.read()
        lines = s.split("\n")
        total = int(lines[0].split(":")[1].strip().split(" ")[0])
        available = int(lines[2].split(":")[1].strip().split(" ")[0])
    return round(100 * (total - available) / total)


def get_power_draw() -> float:
    files = glob.glob("/sys/class/power_supply/BAT*/power_now")
    if files:
        with open(files[0], "r") as f:
            power_draw = int(f.read()) / 1_000_000
        return round(power_draw, 1)
    else:
        return 0


def format_idle_time(idle_time: int) -> str:
    idlestr = ""
    if idle_time > 60 * 60 * 24:
        idlestr += f"{idle_time // (60 * 60 * 24)}d "
    if idle_time > 60 * 60:
        idlestr += f"{idle_time // (60 * 60) % 24}h "
    if idle_time > 60:
        idlestr += f"{idle_time // 60 % 60}m "
    idlestr += f"{idle_time % 60}s"
    return idlestr


gasPricePath = Path("/tmp/gasPrice.json")
ethPricePath = Path("/tmp/ethPrice.json")
APIKEY = "8AKPUEVKW3UNFKIXRTS5HW5WMWG1UX68QH"


def store_gas_price():
    try:
        r = requests.get(
            f"https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey={APIKEY}"
        )
        r.raise_for_status()
        data = r.json()
        with open(gasPricePath, "w") as f:
            json.dump(data, f)
    except Exception as e:
        logger.info(f"Couldn't get gas price: {e}")


def get_gas_price() -> float | None:
    now = datetime.now()
    if not gasPricePath.exists():
        store_gas_price()
    else:
        modified_time = datetime.fromtimestamp(gasPricePath.stat().st_mtime)
        if modified_time < now - timedelta(minutes=10):
            store_gas_price()

    with open(gasPricePath, "r") as f:
        d = json.load(f)
    try:
        return round(float(d["result"]["SafeGasPrice"]))
    except TypeError:
        logger.error("Couldn't read gas price response")
        return None


def store_eth_price():
    try:
        r = requests.get(
            f"https://api.etherscan.io/api?module=stats&action=ethprice&apikey={APIKEY}"
        )
        r.raise_for_status()
        data = r.json()
        with open(ethPricePath, "w") as f:
            json.dump(data, f)
    except Exception as e:
        logger.info(f"Couldn't get gas price: {e}")


def get_eth_price():
    now = datetime.now()
    if not ethPricePath.exists():
        store_eth_price()
    else:
        modified_time = datetime.fromtimestamp(ethPricePath.stat().st_mtime)
        if modified_time < now - timedelta(minutes=1):
            store_eth_price()

    with open(ethPricePath, "r") as f:
        d = json.load(f)
    return round(float(d["result"]["ethusd"]))


def print_line(message):
    """Non-buffered printing to stdout."""
    sys.stdout.write(message + "\n")
    sys.stdout.flush()


def read_line():
    """Interrupted respecting reader for stdin."""
    # try reading a line, removing any extra whitespace
    try:
        line = sys.stdin.readline().strip()
        # i3status sends EOF, or an empty line
        if not line:
            sys.exit(3)
        return line
    # exit on ctrl-c
    except KeyboardInterrupt:
        sys.exit()


def colorpick(
    value,
    min_value=0,
    max_value=100,
    min_color="#333333",
    max_color="#FFFFFF",
    above_max_color="#FF0000",
    below_min_color="#0000FF",
):
    if value > max_value:
        return above_max_color
    elif value < min_value:
        return below_min_color
    else:
        min_color_v = [int("0x" + c, 16) for c in min_color[1:]]
        max_color_v = [int("0x" + c, 16) for c in max_color[1:]]
        diff_color = [b - a for a, b in zip(min_color_v, max_color_v)]
        step = (value - min_value) / (max_value - min_value)
        color = "".join(
            [hex(round(m + d * step))[2:] for m, d in zip(min_color_v, diff_color)]
        )
        return "#" + color


if __name__ == "__main__":
    # Skip the first line which contains the version header.
    print_line(read_line())

    # The second line contains the start of the infinite array.
    print_line(read_line())

    while True:
        line, prefix = read_line(), ""
        # ignore comma at start of lines
        if line.startswith(","):
            line, prefix = line[1:], ","

        j = json.loads(line)

        # insert information into the start of the json, but could be anywhere
        # CHANGE THIS LINE TO INSERT SOMETHING ELSE
        # j.insert(0, {'full_text': '%s' % get_governor(), 'name': 'gov'})

        ram_usage = get_ram_usage()
        j.insert(
            1,
            {
                "full_text": "🐏 %s%%" % ram_usage,
                "name": "brightness",
                "color": colorpick(
                    ram_usage,
                    max_value=85,
                    min_color="#00FF00",
                    max_color="#FFFF00",
                ),
            },
        )

        power_draw = get_power_draw()
        if power_draw:
            j.insert(
                1,
                {
                    "full_text": "⚡ %sW" % power_draw,
                    "name": "brightness",
                    "color": "#FFFF00",
                },
            )

        brightness = get_screen_brightness()
        if brightness is not None:
            brightnesscolor = colorpick(
                brightness, min_color="#883300", max_color="#FFFF00"
            )
            j.insert(
                0,
                {
                    "full_text": "🌞 %s%%" % brightness,
                    "name": "brightness",
                    "color": brightnesscolor,
                },
            )

        gwei = get_gas_price()
        if gwei:
            j.insert(
                0,
                {
                    "full_text": f"⛽ {gwei}",
                    "name": "brightness",
                    "color": colorpick(
                        gwei,
                        min_value=1,
                        max_value=100,
                        min_color="#00FF00",
                        max_color="#FF5555",
                        above_max_color="#FFFFFFF",
                    ),
                },
            )

        ethusd = get_eth_price()
        j.insert(
            0,
            {
                "full_text": f"ETH ${ethusd}",
                "name": "brightness",
                "color": "#00FF00",
            },
        )

        idletime = get_idletime()
        idlecolor = colorpick(
            idletime,
            max_value=3 * 60,
            max_color="#AAAAAA",
            above_max_color="#FF5500",
        )
        j.insert(
            0,
            {
                "full_text": "💤 %s" % format_idle_time(idletime),
                "name": "idle",
                "color": idlecolor,
            },
        )

        # and echo back new encoded json
        print_line(prefix + json.dumps(j))
