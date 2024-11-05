#!/bin/bash

# Read values from config.ini
CONFIG_FILE="config.ini"

# Extract IPs and SleepTime from the config file
IPS=$(awk -F '= ' '/^IPs/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
sleep_time=$(awk -F '= ' '/^sleep_time/ {print $2}' "$CONFIG_FILE")

# Initialize the IP_ARRAY as an empty array
IP_ARRAY=()

# Manually split the IPs and populate the array
while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        IP_ARRAY+=("$i")
    done
done <<< "$IPS"

# Convert the comma-separated IPs into an array
#IFS=',' read -r -a IP_ARRAY <<< "$IPS"

# Create a dictionary to keep track of the connection status of each IP
declare -A CONNECTION_STATUS

# Initialize all IPs as connected
for IP in "${IP_ARRAY[@]}"; do
    CONNECTION_STATUS[$IP]=false
#    echo "Initialized $IP to ${CONNECTION_STATUS[$IP]}"  # Debug output
done

# Infinite loop to keep monitoring the servers
while true; do
    for IP in "${IP_ARRAY[@]}"; do
        # Execute the ping command and capture output and exit status
        OUTPUT=$(ping -c 1 -W 5 "$IP" 2>&1)  # Redirect both stdout and stderr
        STATUS=$?

        if [ $STATUS -eq 0 ]; then
            # If the server is reachable and was previously disconnected
            if [ "${CONNECTION_STATUS[$IP]}" = false ]; then
                echo "Ping to $IP successful - Connected"
                CONNECTION_STATUS[$IP]=true
            fi
        else
            # If the server is unreachable and was previously connected
            if [ "${CONNECTION_STATUS[$IP]}" = true ]; then
                echo "Ping to $IP failed - Disconnected"
                CONNECTION_STATUS[$IP]=false
            fi
        fi

    done

    # Wait for the specified interval before the next check
    sleep "$sleep_time"
done
