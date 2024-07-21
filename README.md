# Temporary Sleep Toggle for Windows 11
This powershell script allow you to temporary toggle sleep to off. It doesn't need to be run as administrator.

It might work with Windows 10, I haven't tried it. It shouldn't mess up anything too bad, maybe it would read the current sleep settings wrong. I based my code on an example for Windows 7.

It assumes Hibernation is disabled and sleep is not. In the sense that it wasn't turned off the hard way.

When sleep is soft disabled (settings are set to 'Never') it will ask you if you want to enable sleep, the default settings are:
- Display off after 5 min
- Go to sleep after 20 min

In the future I will add the option for custom settings and a check for hibernation. It also doesn't touch the unplugged sleep settings.

# How to use
## As a Shortcut
Save the script somewhere and create a new shortcut. When asked for the location of the item, enter this:
powershell.exe -WindowStyle Hidden -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\toggle-sleep.ps1"

Just press 'OK' to re-enable sleep.
