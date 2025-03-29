#!/bin/bash

read -rp "Verify if profile is correct. Check if sync is wrong from: chrome://sync-internals/. Find \"Profile Path\" directory from: chrome://version."

# Check if this is the right profile. Currently set to default chrome profile.
cd /home/adharsh/.config/google-chrome/Default
rm 'Login Data'*
killall chrome
