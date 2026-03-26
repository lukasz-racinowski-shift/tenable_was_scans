#!/bin/bash

# REQUIRED VARIABLES
ACCESS_KEY="xx"
SECRET_KEY="xx"


# What string to look for in the scan name to delete it?
SEARCH_STRING="WAS_Scan_" 

echo "Searching for scans containing: '$SEARCH_STRING' in their name..."

# 1. Fetch the raw response using the correct POST search endpoint
RAW_RESPONSE=$(curl -s -X POST "https://cloud.tenable.com/was/v2/configs/search" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-apikeys: accessKey=$ACCESS_KEY;secretKey=$SECRET_KEY" \
  -d '{"limit": 500}')

# 2. Check if the response contains the word "items" (which means success)
if ! echo "$RAW_RESPONSE" | grep -q '"items"'; then
    echo "[ERROR] API did not return a valid JSON list. Here is what it returned:"
    echo "$RAW_RESPONSE"
    exit 1
fi

# 3. Safely extract config_ids using jq's --arg parameter
SCAN_IDS=$(echo "$RAW_RESPONSE" | jq -r --arg search "$SEARCH_STRING" '.items[] | select(.name != null and (.name | contains($search))) | .config_id')

# Check if any scans were found
if [ -z "$SCAN_IDS" ]; then
    echo "[INFO] No scans found matching the criteria."
    exit 0
fi

# Loop through and delete the found scans
for ID in $SCAN_IDS; do
    echo "Deleting scan with ID: $ID ..."
    
    # Send the DELETE request
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "https://cloud.tenable.com/was/v2/configs/$ID" \
         -H "accept: application/json" \
         -H "x-apikeys: accessKey=$ACCESS_KEY;secretKey=$SECRET_KEY")

    # The API usually returns 200, 202, or 204 on successful deletion
    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 202 ] || [ "$HTTP_STATUS" -eq 204 ]; then
        echo "[SUCCESS] Deleted scan $ID"
    else
        echo "[ERROR] Failed to delete scan $ID. HTTP Status: $HTTP_STATUS"
    fi

    # Small delay to prevent API rate limiting
    sleep 1
done

echo "Cleanup finished!"
