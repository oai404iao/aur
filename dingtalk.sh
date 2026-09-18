#!/bin/bash -e
# Keep upstream defaults, but allow users to select XCB or adjust scaling.
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM-wayland;xcb}"
export QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR-1}"
cd /opt/dingtalk/release
exec ./com.alibabainc.dingtalk "$@"
