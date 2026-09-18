#!/bin/bash -e
# Bundled Qt works with XCB and its Fcitx plugin; preserve explicit overrides.
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM-xcb}"
export QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR-1}"
export QT_IM_MODULE="${QT_IM_MODULE-fcitx}"
export GTK_IM_MODULE="${GTK_IM_MODULE-fcitx}"
# Route GTK3 native file dialogs through the desktop's configured portal.
export GTK_USE_PORTAL="${GTK_USE_PORTAL-1}"
cd /opt/dingtalk/release
exec ./com.alibabainc.dingtalk "$@"
