#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Portable widget backups. Never execute commands or extract archive paths."""

import copy
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from urllib.parse import unquote, urlsplit
import zipfile

FORMAT = "de.agundur.khoneycomb"
MAX_TOTAL = 64 * 1024 * 1024
MAX_IMAGE = 16 * 1024 * 1024
MAX_JSON = 1024 * 1024
RANGES = {"hexSize": (40, 400), "columns": (0, 20), "spacing": (0, 60),
          "backgroundDim": (0, 100), "bevelStrength": (-150, 150),
          "gridPadding": (0, 60), "textSize": (6, 60)}
CHOICES = {"orientation": ("flat", "pointy"),
           "backgroundFillMode": ("fill", "fit", "stretch")}
COLORS = ("placeholderColor", "textColor")
KEYS = set(RANGES) | set(CHOICES) | set(COLORS) | {"backgroundImage", "slots"}
ASSET = re.compile(r"assets/[a-f0-9]{64}\.(png|jpg|jpeg|webp|svg|gif|bmp|ico|avif)")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def text(value):
    return isinstance(value, str) and len(value) <= 16384 and "\0" not in value


def color(value):
    return isinstance(value, str) and re.fullmatch(r"#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{8})", value)


def validate(settings):
    require(isinstance(settings, dict) and set(settings) == KEYS, "Invalid configuration fields.")
    for key, (low, high) in RANGES.items():
        require(type(settings[key]) is int and low <= settings[key] <= high,
                "Invalid value for " + key)
    for key, choices in CHOICES.items():
        require(settings[key] in choices, "Invalid value for " + key)
    for key in COLORS:
        require(color(settings[key]), "Invalid color for " + key)
    require(text(settings["backgroundImage"]), "Invalid background image.")
    slots = settings["slots"]
    require(isinstance(slots, list) and len(slots) <= 500, "Invalid slot list (maximum 500).")
    for slot in slots:
        require(isinstance(slot, dict) and set(slot) == {"image", "command", "zoom", "color"},
                "Invalid hexagon fields.")
        require(text(slot["image"]) and text(slot["command"]), "Invalid image or command.")
        require(type(slot["zoom"]) is int and 40 <= slot["zoom"] <= 300, "Invalid zoom.")
        require(slot["color"] == "" or color(slot["color"]), "Invalid hexagon color.")
    return settings


def images(settings):
    yield settings, "backgroundImage"
    for slot in settings["slots"]:
        yield slot, "image"


def local_path(value):
    url = urlsplit(value)
    if url.scheme:
        require(url.scheme == "file" and url.netloc in ("", "localhost"),
                "Only local files are supported: " + value)
        return Path(unquote(url.path))
    require(Path(value).is_absolute(), "An absolute file path is required: " + value)
    return Path(value)


def atomic_write(path, data):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
            temporary = stream.name
            stream.write(data)
        os.replace(temporary, path)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)


def export_backup(destination, settings):
    settings = copy.deepcopy(validate(settings))
    assets = {}
    for owner, key in images(settings):
        if not owner[key]:
            continue
        path = local_path(owner[key])
        suffix = path.suffix.lower()
        name = "assets/" + "0" * 64 + suffix
        require(ASSET.fullmatch(name), "Unsupported image type: " + str(path))
        with path.open("rb") as stream:
            data = stream.read(MAX_IMAGE + 1)
        require(len(data) <= MAX_IMAGE, "Image exceeds 16 MiB: " + str(path))
        name = "assets/" + hashlib.sha256(data).hexdigest() + suffix
        assets[name] = data
        require(sum(map(len, assets.values())) <= MAX_TOTAL, "Images exceed 64 MiB.")
        owner[key] = name
    manifest = json.dumps({"format": FORMAT, "version": 1, "settings": settings}).encode()
    require(len(manifest) <= MAX_JSON, "Configuration is too large.")
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("manifest.json", manifest)
        for name, data in assets.items():
            archive.writestr(name, data)
    require(buffer.tell() <= MAX_TOTAL, "Backup exceeds 64 MiB.")
    atomic_write(local_path(destination), buffer.getvalue())
    return {"count": len(settings["slots"])}


def read_backup(source):
    with local_path(source).open("rb") as stream:
        raw = stream.read(MAX_TOTAL + 1)
    require(len(raw) <= MAX_TOTAL, "Backup exceeds 64 MiB.")
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        require(len(entries) <= 502 and len(set(names)) == len(names), "Invalid archive entries.")
        require(sum(entry.file_size for entry in entries) <= MAX_TOTAL + MAX_JSON,
                "Backup contents exceed 65 MiB.")
        require("manifest.json" in names, "Missing configuration manifest.")
        for entry in entries:
            limit = MAX_JSON if entry.filename == "manifest.json" else MAX_IMAGE
            require(entry.file_size <= limit and not entry.is_dir(), "Invalid archive entry size.")
            require(entry.filename == "manifest.json" or ASSET.fullmatch(entry.filename),
                    "Unexpected archive entry.")
        manifest = json.loads(archive.read("manifest.json"))
        require(isinstance(manifest, dict) and manifest.get("format") == FORMAT
                and type(manifest.get("version")) is int and manifest["version"] == 1,
                "Unsupported KHoneycomb backup format or version.")
        settings = validate(manifest.get("settings"))
        assets = {}
        for owner, key in images(settings):
            name = owner[key]
            if not name:
                continue
            require(ASSET.fullmatch(name) and name in names, "Missing or invalid image asset.")
            if name not in assets:
                data = archive.read(name)
                require(hashlib.sha256(data).hexdigest() == Path(name).stem, "Image checksum mismatch.")
                assets[name] = data
    return settings, assets, hashlib.sha256(raw).hexdigest()


def inspect_backup(source):
    settings, _, digest = read_backup(source)
    return {"count": len(settings["slots"]), "digest": digest}


def import_backup(source, expected_digest):
    settings, assets, digest = read_backup(source)
    require(digest == expected_digest, "The backup changed. Please select it again.")
    data_home = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    require(data_home.is_absolute(), "XDG_DATA_HOME must be absolute.")
    directory = data_home / "khoneycomb/imported"
    directory.mkdir(parents=True, exist_ok=True)
    for name, data in assets.items():
        atomic_write(directory / Path(name).name, data)
    for owner, key in images(settings):
        if owner[key]:
            owner[key] = str(directory / Path(owner[key]).name)
    return {"settings": settings}


def main():
    try:
        operation, source = sys.argv[1:3]
        if operation == "export":
            result = export_backup(source, json.loads(sys.argv[3]))
        elif operation == "inspect":
            result = inspect_backup(source)
        elif operation == "import":
            result = import_backup(source, sys.argv[3])
        else:
            raise ValueError("Unknown backup operation.")
        print(json.dumps({"ok": True, **result}))
    except Exception as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
