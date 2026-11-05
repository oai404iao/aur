"""Patch and verify the privacy defaults of the pinned official Bruno binary."""

import json
from pathlib import Path
import re
import sys


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"Expected exactly one upstream pattern: {old!r}")
    return text.replace(old, new)


def patch(root):
    path = root / "src/store/preferences.js"
    text = path.read_text()
    for old, new in (
        ("downloadUpdates: true", "downloadUpdates: false"),
        ("telemetry: {\n    enabled: true", "telemetry: {\n    enabled: false"),
        ("'autoupdate.downloadUpdates', true", "'autoupdate.downloadUpdates', false"),
        ("'telemetry.enabled', true", "'telemetry.enabled', false"),
    ):
        text = replace_once(text, old, new)
    path.write_text(text)

    path = root / "src/utils/license.js"
    text = path.read_text()
    # Optional analytics correlation IDs are not license/device credentials.
    text, count = re.subn(
        r"(?m)^( +)(appDistinctId|posthogDistinctId)$", r"\1\2: undefined", text
    )
    if count != 3:
        raise ValueError(f"Expected three license analytics fields, found {count}")
    text = replace_once(
        text,
        "  if (appDistinctId) {\n    body.appDistinctId = appDistinctId;\n  }",
        "",
    )
    path.write_text(text)

    # The release renderer inlines the key; runtime environment variables cannot
    # unset it. Both event capture and onboarding feature flags guard on this key.
    count = 0
    for path in (root / "web").rglob("*.js"):
        text = path.read_text()
        text, matches = re.subn(r'"phc_[A-Za-z0-9]+"', '""', text)
        if matches:
            path.write_text(text)
            count += matches
    if count != 2:
        raise ValueError(f"Expected two compiled PostHog keys, found {count}")


def check(root, version):
    if json.loads((root / "package.json").read_text())["version"] != version:
        raise ValueError("Binary package version differs from PKGBUILD")
    text = (root / "src/store/preferences.js").read_text()
    for expected in (
        "downloadUpdates: false",
        "telemetry: {\n    enabled: false",
        "'autoupdate.downloadUpdates', false",
        "'telemetry.enabled', false",
    ):
        if text.count(expected) != 1:
            raise ValueError(f"Missing privacy default: {expected}")
    for path in (root / "web").rglob("*.js"):
        if re.search(r"phc_[A-Za-z0-9]+", path.read_text()):
            raise ValueError(f"PostHog key remains in {path}")
    license_code = (root / "src/utils/license.js").read_text()
    if len(re.findall(r"(?:appDistinctId|posthogDistinctId): undefined", license_code)) != 3:
        raise ValueError("License analytics fields were not removed")
    if "body.appDistinctId =" in license_code:
        raise ValueError("Upgrade request still sends analytics ID")
    updater = (root / "src/ipc/updater.js").read_text()
    if not re.search(r"if \(isPortableBuild\(\)\) \{[^}]*return;", updater):
        raise ValueError("Upstream portable update guard changed")
    print(f"Bruno {version}: archive version, privacy defaults, keys and updater guard OK")


if __name__ == "__main__":
    mode, directory, *args = sys.argv[1:]
    if mode == "patch":
        patch(Path(directory))
    elif mode == "check":
        check(Path(directory), *args)
    else:
        raise ValueError(f"Unknown mode: {mode}")
