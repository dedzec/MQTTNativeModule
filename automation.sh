#!/bin/bash

# ~/Android/Sdk/tools/bin/uiautomatorviewer
adb pull $(adb shell uiautomator dump | grep -oP '[^ ]+.xml') /tmp/view.xml

coords=$(perl -ne 'printf "%d %d\n", ($1+$3)/2, ($2+$4)/2 if /text="OK"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/' /tmp/view.xml)

adb shell input tap $coords

exit 0
