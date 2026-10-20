#!/usr/bin/env python3
"""Exercise portability, validation, atomic writes and the helper protocol."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "package/contents/tools/backup.py"
spec = importlib.util.spec_from_file_location("backup", HELPER)
backup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backup)


class BackupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.image = self.directory / "icon ' $(touch NEVER) ü.svg"
        self.image.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>')
        self.settings = dict(hexSize=90, columns=0, spacing=5, orientation="flat",
                             placeholderColor="#ffd021", backgroundImage=str(self.image),
                             backgroundFillMode="fill", backgroundDim=40, bevelStrength=-50,
                             gridPadding=0, textColor="#000000", textSize=14,
                             slots=[dict(image=self.image.as_uri(), command="printf 'hello'; $(anything)",
                                         zoom=100, color="#80ffffff")])
        self.path = self.directory / "backup ü.khoneycomb"
        self.env = patch.dict(os.environ, {"XDG_DATA_HOME": str(self.directory / "data")})
        self.env.start()
        self.addCleanup(self.env.stop)

    def archive(self, manifest, assets=None):
        with zipfile.ZipFile(self.path, "w") as archive:
            archive.writestr("manifest.json", json.dumps(manifest))
            for name, data in (assets or {}).items():
                archive.writestr(name, data)

    def test_schema_covers_all_widget_settings(self):
        tree = ET.parse(ROOT / "package/contents/config/main.xml")
        keys = {entry.attrib["name"] for entry in tree.iter() if entry.tag.endswith("}entry")}
        self.assertEqual(keys, backup.KEYS)

    def test_roundtrip_moves_images_and_preserves_commands(self):
        original = copy.deepcopy(self.settings)
        backup.export_backup(self.path.as_uri(), self.settings)
        self.assertEqual(original, self.settings)
        with zipfile.ZipFile(self.path) as archive:
            self.assertEqual(len(archive.namelist()), 2)  # Shared icon/background deduplicated.
        self.image.unlink()  # No source images available on destination machine.
        preview = backup.inspect_backup(self.path.as_uri())
        self.assertEqual(preview["count"], 1)
        self.assertFalse((self.directory / "data").exists())  # Inspection has no side effects.
        settings = backup.import_backup(self.path.as_uri(), preview["digest"])["settings"]
        self.assertEqual(settings["slots"][0]["command"], original["slots"][0]["command"])
        self.assertEqual(settings["slots"][0]["image"], settings["backgroundImage"])
        self.assertEqual(Path(settings["backgroundImage"]).read_text(),
                         '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>')
        settings["slots"][0]["image"] = original["slots"][0]["image"]
        settings["backgroundImage"] = original["backgroundImage"]
        self.assertEqual(settings, original)

    def test_missing_image_preserves_existing_backup(self):
        self.path.write_bytes(b"previous backup")
        self.image.unlink()
        with self.assertRaises(OSError):
            backup.export_backup(self.path.as_uri(), self.settings)
        self.assertEqual(self.path.read_bytes(), b"previous backup")

    def test_empty_widget(self):
        self.settings["slots"] = []
        self.settings["backgroundImage"] = ""
        backup.export_backup(self.path.as_uri(), self.settings)
        self.assertEqual(backup.inspect_backup(self.path.as_uri())["count"], 0)

    def test_rejects_changed_backup_after_confirmation(self):
        backup.export_backup(self.path.as_uri(), self.settings)
        preview = backup.inspect_backup(self.path.as_uri())
        self.settings["hexSize"] = 100
        backup.export_backup(self.path.as_uri(), self.settings)
        with self.assertRaisesRegex(ValueError, "changed"):
            backup.import_backup(self.path.as_uri(), preview["digest"])
        self.assertFalse((self.directory / "data").exists())

    def test_invalid_settings(self):
        for key, value in [("hexSize", True), ("hexSize", 0), ("slots", "[]"),
                           ("orientation", "unknown"), ("placeholderColor", "script"),
                           ("slots", [dict(image="", command="", zoom=999, color="")])]:
            with self.subTest(key=key, value=value):
                settings = {**self.settings, key: value}
                with self.assertRaises(ValueError):
                    backup.validate(settings)

    def test_rejects_unsupported_version_and_missing_assets(self):
        for version in (2, True, 1):
            self.archive({"format": backup.FORMAT, "version": version, "settings": self.settings})
            with self.assertRaises(ValueError):
                backup.inspect_backup(self.path.as_uri())

    def test_rejects_traversal(self):
        self.archive({"format": backup.FORMAT, "version": 1, "settings": self.settings},
                     {"../../escape.svg": b"bad"})
        with self.assertRaisesRegex(ValueError, "Unexpected archive entry"):
            backup.inspect_backup(self.path.as_uri())

    def test_rejects_corrupt_image(self):
        backup.export_backup(self.path.as_uri(), self.settings)
        with zipfile.ZipFile(self.path) as archive:
            contents = {name: archive.read(name) for name in archive.namelist()}
        asset = next(name for name in contents if name.startswith("assets/"))
        with zipfile.ZipFile(self.path, "w") as archive:
            for name, data in contents.items():
                archive.writestr(name, b"corrupt" if name == asset else data)
        with self.assertRaisesRegex(ValueError, "checksum"):
            backup.inspect_backup(self.path.as_uri())

    def test_image_size_limit(self):
        with patch.object(backup, "MAX_IMAGE", 1):
            with self.assertRaisesRegex(ValueError, "exceeds"):
                backup.export_backup(self.path.as_uri(), self.settings)
        self.assertFalse(self.path.exists())

    def test_cli_json_and_errors(self):
        result = subprocess.run([sys.executable, "-B", str(HELPER), "export", self.path.as_uri(),
                                 json.dumps(self.settings)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(json.loads(result.stdout)["ok"])
        result = subprocess.run([sys.executable, "-B", str(HELPER), "inspect", "/nonexistent"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertFalse(json.loads(result.stdout)["ok"])


if __name__ == "__main__":
    unittest.main()
