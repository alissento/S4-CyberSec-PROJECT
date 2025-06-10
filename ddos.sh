#!/bin/bash

# --- Configuration ---
TARGET_URL="https://nknez.tech/dashboard"                   # URL to target for the DDoS simulation
NUM_REQUESTS=2000                                           # Total number of requests to send
MAX_CONCURRENT_CLIENT_JOBS=50                               # Max concurrent curl processes

# --- WARNING ---
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! WARNING: This script will send $NUM_REQUESTS requests to $TARGET_URL"
echo "!!! with up to $MAX_CONCURRENT_CLIENT_JOBS concurrent connections from this machine."
echo "!!!"
echo "!!!           >>> ONLY RUN THIS AGAINST SYSTEMS YOU OWN <<<           !!!"
echo "!!!      AND HAVE EXPLICIT PERMISSION TO TEST IN THIS MANNER.       !!!"
echo "!!!"
echo "!!! Misuse can lead to your IP being blocked or other consequences. !!!"
echo "!!! This can also put load on your own infrastructure.              !!!"
echo "!!!"
echo "!!! Press Ctrl+C within 7 seconds to ABORT.                         !!!"
echo "!!! Or press Enter to CONTINUE...                                   !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

read -t 7 -r -p "Proceed? (Enter/Timeout to continue, Ctrl+C to abort): "
if [ $? -ne 0 ] && [ $? -ne 142 ]; then # 142 is timeout
    echo "Aborted by user."
    exit 1
fi
echo "Proceeding with test..."


# --- Script Logic ---
echo "Starting DDoS simulation against $TARGET_URL..."
echo "Sending $NUM_REQUESTS requests in total."
echo "Limiting concurrent jobs from this client to $MAX_CONCURRENT_CLIENT_JOBS."

# Temporary file to store all HTTP status codes
STATUS_CODES_FILE=$(mktemp)

# Counter for launched requests
launched_count=0

for i in $(seq 1 "$NUM_REQUESTS")
do
    # Limit the number of concurrent background jobs initiated by this script
    while (( $(jobs -p | wc -l) >= MAX_CONCURRENT_CLIENT_JOBS )); do
        sleep 0.1 # Wait a bit for a job to finish
    done

    # Run curl in the background
    (
        # -s: silent mode (no progress meter)
        # -o /dev/null: discard response body
        # -w "%{http_code}": output only the HTTP status code
        # --connect-timeout 5: max time to connect
        # -m 10: max time for the whole operation
        status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -m 10 "$TARGET_URL")
        echo "Request $i: Status $status_code" # This output will be interleaved
        echo "$status_code" >> "$STATUS_CODES_FILE"
    ) &

    launched_count=$((launched_count + 1))
    if (( launched_count % 100 == 0 )); then
        echo "Launched $launched_count requests so far..."
    fi
done

echo "All $NUM_REQUESTS request processes have been launched. Waiting for them to complete..."
wait # Wait for all backgrounded curl jobs to finish

echo -e "\n--- Summary of HTTP Status Codes ---"
if [ -s "$STATUS_CODES_FILE" ]; then
    sort "$STATUS_CODES_FILE" | uniq -c | sort -nr
else
    echo "No status codes recorded. Check if requests were sent."
fi
echo "------------------------------------"

# Clean up
rm "$STATUS_CODES_FILE"

echo "Test finished."
echo "Check your WAF logs and server metrics to see how the traffic was handled."
echo "Look for HTTP status codes like:"
echo "  - 200 OK (WAF didn't block, or request was allowed)"
echo "  - 403 Forbidden (WAF likely blocked)"
echo "  - 429 Too Many Requests (WAF rate limiting)"
echo "  - 503 Service Unavailable (Server overloaded or WAF mitigation)"
echo "  - Other error codes (e.g., connection timeouts if server is overwhelmed)"