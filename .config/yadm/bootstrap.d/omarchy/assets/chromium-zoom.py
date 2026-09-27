#!/usr/bin/env python3
"""Set Chromium's default page zoom once per yadm bootstrap."""

import argparse
import json
import math
import os
import stat
import subprocess
import tempfile
from pathlib import Path


def chromium_running():
    return subprocess.run(["pgrep", "-x", "chromium"], capture_output=True).returncode == 0


def zoom_is_target(data):
    zoom = data.get("partition", {}).get("default_zoom_level", {}).get("x")
    target = math.log(1.25) / math.log(1.2)
    return isinstance(zoom, (int, float)) and math.isclose(zoom, target)


def set_zoom(preferences):
    data = json.loads(preferences.read_text()) if preferences.exists() else {}
    if zoom_is_target(data):
        return

    data.setdefault("partition", {}).setdefault("default_zoom_level", {})["x"] = math.log(1.25) / math.log(1.2)
    preferences.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(preferences.stat().st_mode) if preferences.exists() else 0o600
    fd, staged = tempfile.mkstemp(prefix=".Preferences.", dir=preferences.parent)
    try:
        with os.fdopen(fd, "w") as output:
            json.dump(data, output, separators=(",", ":"))
        os.chmod(staged, mode)
        os.replace(staged, preferences)
    except BaseException:
        os.unlink(staged)
        raise


parser = argparse.ArgumentParser()
parser.add_argument("action", choices=("bootstrap", "apply-pending"))
parser.add_argument("preferences", type=Path)
args = parser.parse_args()

pending = args.preferences.parent / ".yadm-default-zoom-pending"
if args.action == "bootstrap":
    if chromium_running():
        data = json.loads(args.preferences.read_text()) if args.preferences.exists() else {}
        if zoom_is_target(data):
            pending.unlink(missing_ok=True)
        else:
            pending.parent.mkdir(parents=True, exist_ok=True)
            pending.touch(mode=0o600)
            print("Chromium is running; 125% page zoom will apply at its next start.")
    else:
        set_zoom(args.preferences)
        pending.unlink(missing_ok=True)
elif pending.exists() and not chromium_running():
    set_zoom(args.preferences)
    pending.unlink()
