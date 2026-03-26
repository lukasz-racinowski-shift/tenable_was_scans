#!/bin/bash

# REQUIRED VARIABLES
ACCESS_KEY="xx"
SECRET_KEY="xx"
OWNER_ID="52fb3009-de2b-4d24-a209-409bc0bfeaea"
TEMPLATE_ID="b223f18e-5a94-4e02-b560-77a4a8246cd3"
SCANNER_ID=613839 # Ireland Cloud Scanners
NOTIFICATION_EMAIL="lukasz.racinowski@shift-technology.com" 
INPUT_FILE="shift_urls"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "[ERROR] File $INPUT_FILE does not exist!"
    exit 1
fi

echo "Starting mass scan creation..."

# Loop through the file line by line
while IFS= read -r RAW_URL || [ -n "$RAW_URL" ]; do
    
    # Strip the hidden Windows carriage return (\r) character
    URL=$(echo "$RAW_URL" | tr -d '\r')

    # Skip empty lines
    if [ -z "$URL" ]; then
        continue
    fi

    # Strip http:// or https:// from the URL to get just the domain
    DOMAIN=${URL#*://}
    
    # Define the scan name dynamically based on the stripped domain
    SCAN_NAME="WAS_Scan_$DOMAIN"

    echo "Creating scan for: $URL (Name: $SCAN_NAME)..."

    # Send the API request and capture only the HTTP status code
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://cloud.tenable.com/was/v2/configs" \
         -H "Content-Type: application/json" \
         -H "x-apikeys: accessKey=$ACCESS_KEY;secretKey=$SECRET_KEY" \
         -d '{
           "name": "'"$SCAN_NAME"'",
           "template_id": "'"$TEMPLATE_ID"'",
           "owner_id": "'"$OWNER_ID"'",
           "scanner_id": '"$SCANNER_ID"',
           "targets": ["'"$URL"'"],
           "schedule": {
             "enabled": true,
             "starttime": "20260404T220000",
             "timezone": "Europe/Warsaw",
             "rrule": "FREQ=MONTHLY;BYDAY=SA"
           },
           "notifications": {
             "emails": ["'"$NOTIFICATION_EMAIL"'"]
           }
         }')

    # Check if the request was successful (HTTP 200, 201, or 202)
    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ] || [ "$HTTP_STATUS" -eq 202 ]; then
        echo "[SUCCESS] Created scan: $SCAN_NAME"
    else
        echo "[ERROR] Failed to create scan for $URL. HTTP Status: $HTTP_STATUS"
    fi

    # Small delay to prevent API rate limiting (1 second)
    sleep 1

done < "$INPUT_FILE"

echo "Processing finished."
