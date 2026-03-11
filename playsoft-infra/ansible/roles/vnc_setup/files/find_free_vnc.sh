#!/bin/bash

START_VNC_PORT="$1"
MAX_VNC_PORT="$2"

# Validate input
if [[ -z "$START_VNC_PORT" || -z "$MAX_VNC_PORT" ]]; then
    echo "Usage: $0 <start_vnc_port> <max_vnc_port>"
    exit 2
fi

for n in $(seq "$START_VNC_PORT" "$MAX_VNC_PORT"); do
    port=$((5900 + n))

    # Check if port is in use
    if ss -tulpn | grep -q ":${port} "; then
        # Port is in use → check next
        continue
    fi

    # Free port found
    echo "$n"
    exit 0
done

# No free display
exit 3
