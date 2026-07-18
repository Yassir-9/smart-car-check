#!/usr/bin/env python3
"""
fix_pubspec.py
--------------
يصلح مشكلة "Duplicate mapping key: dev_dependencies" اللي صارت لأن
apply_icon.py ضاف قسم dev_dependencies: جديد بدل ما يدمجه مع الموجود.

شغّله من نفس مجلد frontend:
    python3 fix_pubspec.py
"""

import os
import re

PUBSPEC_PATH = os.path.join(os.getcwd(), "pubspec.yaml")

MARKER = '\ndev_dependencies:\n  flutter_launcher_icons: ^0.13.1\n\nflutter_launcher_icons:'


def main():
    if not os.path.exists(PUBSPEC_PATH):
        print("⚠️ ما لقيت pubspec.yaml في المجلد الحالي.")
        return

    with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    if MARKER not in content:
        print("ℹ️ ما لقيت التكرار المتوقع — يمكن انصلح مسبقًا أو الملف مختلف. تأكد يدويًا.")
        return

    content = content.replace(
        'dev_dependencies:\n  flutter_launcher_icons: ^0.13.1\n\nflutter_launcher_icons:',
        'flutter_launcher_icons:'
    )

    if re.search(r'^dev_dependencies:\s*$', content, flags=re.MULTILINE):
        if "flutter_launcher_icons: ^0.13.1" not in content.split("flutter_launcher_icons:\n  android:")[0]:
            content = re.sub(
                r'^(dev_dependencies:\s*\n)',
                r'\1  flutter_launcher_icons: ^0.13.1\n',
                content,
                count=1,
                flags=re.MULTILINE,
            )
    else:
        print("⚠️ ما لقيت قسم dev_dependencies: أصلي — أضف السطر يدويًا:")
        print('   flutter_launcher_icons: ^0.13.1')

    with open(PUBSPEC_PATH, "w", encoding="utf-8") as f:
        f.write(content)

    print("✅ تم إصلاح pubspec.yaml — جرّب الحين:")
    print("   flutter pub get")
    print("   flutter pub run flutter_launcher_icons")


if __name__ == "__main__":
    main()
