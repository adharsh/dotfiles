#!/bin/bash
# Reset the scaling set by .profile
GDK_SCALE=1 GDK_DPI_SCALE=1 QT_AUTO_SCREEN_SET_FACTOR=0 QT_SCALE_FACTOR=1 QT_FONT_DPI=96 "$@"
