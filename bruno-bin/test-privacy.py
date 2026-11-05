"""Offline regression tests; fixtures never use Bruno's actual user data."""

import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("privacy", Path(__file__).with_name("privacy.py"))
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)


class PrivacyTests(unittest.TestCase):
    def test_exact_replacement(self):
        self.assertEqual(privacy.replace_once("enabled: true", "true", "false"), "enabled: false")

    def test_missing_or_duplicate_pattern_fails(self):
        for text in ("", "true true"):
            with self.assertRaises(ValueError):
                privacy.replace_once(text, "true", "false")

    def test_patch_and_verify(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src/store").mkdir(parents=True)
            (root / "src/ipc").mkdir()
            (root / "src/utils").mkdir()
            (root / "web").mkdir()
            (root / "package.json").write_text('{"version":"4.3.0"}')
            (root / "src/store/preferences.js").write_text(
                "downloadUpdates: true\ntelemetry: {\n    enabled: true\n"
                "'autoupdate.downloadUpdates', true\n'telemetry.enabled', true"
            )
            (root / "src/ipc/updater.js").write_text("if (isPortableBuild()) { return; }")
            (root / "src/utils/license.js").write_text(
                "    appDistinctId\n        appDistinctId\n        posthogDistinctId\n"
                "  if (appDistinctId) {\n    body.appDistinctId = appDistinctId;\n  }"
            )
            renderer = root / "web/index.js"
            renderer.write_text('let a="phc_one",b="phc_two";')
            privacy.patch(root)
            privacy.check(root, "4.3.0")
            self.assertEqual(renderer.read_text(), 'let a="",b="";')
            with self.assertRaises(ValueError):
                privacy.patch(root)
            with self.assertRaises(ValueError):
                privacy.check(root, "0.0.0")
            renderer.write_text('let a="phc_remaining";')
            with self.assertRaises(ValueError):
                privacy.check(root, "4.3.0")


if __name__ == "__main__":
    unittest.main()
