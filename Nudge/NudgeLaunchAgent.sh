#!/bin/bash

# URL to raw file on GitHub
baseURL="https://raw.githubusercontent.com/ringit-euc/macOS/main"
# Name of plist in the repository
fileName="com.github.macadmins.Nudge.plist"
# Base paths
launch_agent_base_path='/Library/LaunchAgents/'

curl -LJ "${baseURL}/${fileName}" -o "$3/${launch_agent_base_path}${fileName}"

# Check the existence of the Laucnh Agent file exit if the file don't exist.
if [ ! -e "$3/${launch_agent_base_path}${fileName}" ]; then
  echo "LaunchAgent missing, exiting"
  exit 1
fi

# Current console user information
console_user=$(stat -f "%Su" /dev/console)
console_user_uid=$(id -u "$console_user")

# Only enable the LaunchAgent if there is a user logged in, otherwise rely on built-in LaunchAgent behavior
if [[ -z "$console_user" ]]; then
  echo "Did not detect user"
elif [[ "$console_user" == "loginwindow" ]]; then
  echo "Detected Loginwindow Environment"
elif [[ "$console_user" == "_mbsetupuser" ]]; then
  echo "Detect SetupAssistant Environment"
elif [[ "$console_user" == "root" ]]; then
  echo "Detect root as currently logged-in user"
else
  # Unload the agent so it can be triggered on re-install
  launchctl asuser "${console_user_uid}" launchctl unload -w "$3/${launch_agent_base_path}${fileName}"
  # Kill Nudge just in case (say someone manually opens it and not launched via launchagent)
  killall Nudge
  # Load the launch agent
  launchctl asuser "${console_user_uid}" launchctl load -w "$3/${launch_agent_base_path}${fileName}"
fi
