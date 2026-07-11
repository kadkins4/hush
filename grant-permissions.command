#!/bin/bash
# grant-permissions.command — one-time helper.
# Double-click this in Finder. It reveals the exact Python binary macOS needs
# to trust, and opens the three Privacy panes you must add it to.
#
# In Input Monitoring and Accessibility: click the "+", press Cmd+Shift+G,
# paste the path printed below, and add it. (Microphone has no "+": it prompts
# the first time you hold the key — just click Allow.)

BIN="$("$HOME/Developer/hush/.venv/bin/python" -c 'import os,sys;print(os.path.realpath(sys.executable))')"

echo "────────────────────────────────────────────────────────"
echo "Grant these THREE permissions to this exact binary:"
echo
echo "    $BIN"
echo
echo "(path copied to your clipboard — paste with Cmd+V after Cmd+Shift+G)"
echo "────────────────────────────────────────────────────────"
printf '%s' "$BIN" | pbcopy

# Reveal the binary in Finder so you can also drag it in if you prefer.
open -R "$BIN"

# Open the three Privacy panes.
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"    # Input Monitoring
sleep 1
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"  # Accessibility
sleep 1
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"     # Microphone

echo
echo "After adding it to Input Monitoring + Accessibility, restart the app:"
echo "    launchctl kickstart -k gui/\$(id -u)/com.kenny.hush"
echo
read -n 1 -s -r -p "Press any key to close this window."
