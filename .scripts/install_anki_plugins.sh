#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it first."
    exit 1
fi

# Function to install a single plugin
install_plugin() {
    local plugin_id=$1
    local response=$(curl -s localhost:8765 -X POST -d "{
        \"action\": \"downloadAddon\",
        \"version\": 6,
        \"params\": {
            \"addonId\": $plugin_id
        }
    }")
    
    local error=$(echo $response | jq -r '.error')
    if [ "$error" != "null" ]; then
        echo "Failed to install plugin $plugin_id: $error"
    else
        echo "Successfully installed plugin $plugin_id"
    fi
}

# Check if plugin IDs are provided
if [ "$#" -eq 0 ]; then
    echo "No plugin IDs provided. Usage: $0 <plugin_id1> <plugin_id2> ..."
    echo "Exiting without making any changes."
    exit 0
fi

# Check if Anki was already running
anki_was_running=false
if pgrep -x anki > /dev/null; then
    anki_was_running=true
    echo "Anki is already running."
else
    echo "Launching Anki..."
    anki &
    sleep 5  # Wait for Anki to start up (adjust if needed)
fi

# Check if AnkiConnect is responding
max_attempts=12
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s localhost:8765 -X POST -d '{"action": "version", "version": 6}' > /dev/null; then
        echo "AnkiConnect is responding."
        break
    fi
    echo "Waiting for AnkiConnect to start..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "AnkiConnect is not responding. Please make sure it's installed and Anki is running properly."
    exit 1
fi

# Install plugins
for plugin in "$@"; do
    install_plugin $plugin
done

echo "Anki plugin installation complete."

# Close Anki if we started it
if [ "$anki_was_running" = false ]; then
    echo "Closing Anki..."
    pkill anki
    sleep 2  # Give Anki some time to close gracefully
    if pgrep -x anki > /dev/null; then
        read -p "Anki is still running. You may want to close it manually."
    else
        echo "Anki has been closed."
    fi
else
    echo "Anki was already running before the script started. Leaving it open."
fi
