echo "Contents of $0"
cat $0
read -p "Verify if profile is correct. Check if sync is wrong from: chrome://sync-internals/. Find directory from: chrome://version."

# Check if this is the right profile. Currently set to default chrome profile.
cd /home/adharsh/.config/google-chrome/Default
rm 'Login Data'*
killall chrome
