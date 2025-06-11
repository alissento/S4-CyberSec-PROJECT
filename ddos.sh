#!/bin/bash

# --- Configuration ---
TARGET_URL="https://nknez.tech/dashboard"
NUM_REQUESTS=2000
MAX_CONCURRENT_CLIENT_JOBS=50

# --- WARNING ---
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! WARNING: This script will send $NUM_REQUESTS requests to $TARGET_URL"
echo "!!! with up to $MAX_CONCURRENT_CLIENT_JOBS concurrent connections from this machine."
echo "!!! This is a simulated DDoS test and should only be run against your own systems"
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

STATUS_CODES_FILE=$(mktemp)

launched_count=0

for i in $(seq 1 "$NUM_REQUESTS")
do
    while (( $(jobs -p | wc -l) >= MAX_CONCURRENT_CLIENT_JOBS )); do
        sleep 0.1

    (
        status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -m 10 "$TARGET_URL")
        echo "Request $i: Status $status_code"
        echo "$status_code" >> "$STATUS_CODES_FILE"
    ) &

    launched_count=$((launched_count + 1))
    if (( launched_count % 100 == 0 )); then
        echo "Launched $launched_count requests so far..."
    fi
done

echo "All $NUM_REQUESTS request processes have been launched. Waiting for them to complete..."
wait

echo -e "\n--- Summary of HTTP Status Codes ---"
if [ -s "$STATUS_CODES_FILE" ]; then
    sort "$STATUS_CODES_FILE" | uniq -c | sort -nr
else
    echo "No status codes recorded. Check if requests were sent."
fi
echo "------------------------------------"

rm "$STATUS_CODES_FILE"

echo "Test finished."
echo "Check your WAF logs and server metrics to see how the traffic was handled."
echo "Look for HTTP status codes like:"
echo "  - 200 OK (WAF didn't block, or request was allowed)"
echo "  - 403 Forbidden (WAF likely blocked)"
echo "  - 429 Too Many Requests (WAF rate limiting)"
echo "  - 503 Service Unavailable (Server overloaded or WAF mitigation)"
echo "  - Other error codes (e.g., connection timeouts if server is overwhelmed)"