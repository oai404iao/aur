"""Test the launcher without installing or executing DingTalk."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


WRAPPER = Path(__file__).resolve().parents[1] / "dingtalk.sh"


class WrapperTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Retain fixtures for inspection; callers can scope TMPDIR to a task directory.
        cls.release = Path(tempfile.mkdtemp(prefix="dingtalk-wrapper-"))
        mock = cls.release / "com.alibabainc.dingtalk"
        mock.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "print(json.dumps({'args': sys.argv[1:], 'pid': os.getpid(),\n"
            " 'shell_pid': int(os.environ['SHELL_PID']),\n"
            " 'platform': os.environ['QT_QPA_PLATFORM'],\n"
            " 'qt_im': os.environ['QT_IM_MODULE'],\n"
            " 'gtk_im': os.environ['GTK_IM_MODULE'],\n"
            " 'portal': os.environ['GTK_USE_PORTAL'],\n"
            " 'scale': os.environ['QT_AUTO_SCREEN_SCALE_FACTOR']}))\n"
            "sys.exit(int(os.environ.get('MOCK_EXIT', '0')))\n"
        )
        mock.chmod(0o755)

    def launch(self, args=(), overrides=None, missing_directory=False):
        env = os.environ.copy()
        for key in (
            "QT_QPA_PLATFORM", "QT_AUTO_SCREEN_SCALE_FACTOR", "QT_IM_MODULE",
            "GTK_IM_MODULE", "GTK_USE_PORTAL", "MOCK_EXIT",
        ):
            env.pop(key, None)
        env.update(overrides or {})
        env["TEST_RELEASE"] = str(self.release)
        cd = (
            "cd() { return 1; }; "
            if missing_directory
            else 'cd() { test "$1" = /opt/dingtalk/release; '
            'builtin cd "$TEST_RELEASE"; }; '
        )
        return subprocess.run(
            ["bash", "-e", "-c",
             cd + 'export SHELL_PID=$$; source "$1" "${@:2}"',
             "wrapper-test", str(WRAPPER), *args],
            env=env, text=True, capture_output=True,
        )

    def test_defaults_arguments_and_exec(self):
        args = ["dingtalk://example/path?a=1&b=2", "with spaces", "", "*"]
        result = self.launch(args)
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["args"], args)
        self.assertEqual(output["platform"], "xcb")
        self.assertEqual(output["qt_im"], "fcitx")
        self.assertEqual(output["gtk_im"], "fcitx")
        self.assertEqual(output["portal"], "1")
        self.assertEqual(output["scale"], "1")
        self.assertEqual(output["pid"], output["shell_pid"])

    def test_user_overrides(self):
        result = self.launch(overrides={
            "QT_QPA_PLATFORM": "wayland", "QT_AUTO_SCREEN_SCALE_FACTOR": "0",
            "QT_IM_MODULE": "ibus", "GTK_IM_MODULE": "ibus", "GTK_USE_PORTAL": "0",
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["platform"], "wayland")
        self.assertEqual(output["scale"], "0")
        self.assertEqual(output["qt_im"], "ibus")
        self.assertEqual(output["gtk_im"], "ibus")
        self.assertEqual(output["portal"], "0")

    def test_explicit_empty_values(self):
        result = self.launch(overrides={
            "QT_QPA_PLATFORM": "", "QT_AUTO_SCREEN_SCALE_FACTOR": "",
            "QT_IM_MODULE": "", "GTK_IM_MODULE": "", "GTK_USE_PORTAL": "",
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["platform"], "")
        self.assertEqual(output["scale"], "")
        self.assertEqual(output["qt_im"], "")
        self.assertEqual(output["gtk_im"], "")
        self.assertEqual(output["portal"], "")

    def test_partial_override_keeps_other_defaults(self):
        result = self.launch(overrides={"GTK_USE_PORTAL": "0"})
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["portal"], "0")
        self.assertEqual(output["platform"], "xcb")
        self.assertEqual(output["qt_im"], "fcitx")
        self.assertEqual(output["gtk_im"], "fcitx")

    def test_exit_status(self):
        self.assertEqual(self.launch(overrides={"MOCK_EXIT": "23"}).returncode, 23)

    def test_failed_cd_does_not_launch(self):
        result = self.launch(missing_directory=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
