#!/bin/bash

# variables
ACCESS_KEY=""
SECRET_KEY=""
TEMPLATE_ID="b223f18e-5a94-4e02-b560-77a4a8246cd3"
TARGET_URL="https://example.com"
SCAN_NAME="Automatic_test_scan"
OWNER_ID="52fb3009-de2b-4d24-a209-409bc0bfeaea"
SCANNER_ID="613839" # Ireland Cloud Scanners
NOTIFICATION_EMAIL="lukasz.racinowski@shift-technology.com"

# Wysłanie zapytania API tworzącego skan w Tenable WAS
curl -s -X POST "https://cloud.tenable.com/was/v2/configs" \
     -H "Content-Type: application/json" \
     -H "x-apikeys: accessKey=$ACCESS_KEY;secretKey=$SECRET_KEY" \
     -d '{
       "name": "'"$SCAN_NAME"'",
       "template_id": "'"$TEMPLATE_ID"'",
       "owner_id": "'"$OWNER_ID"'",
       "targets": ["'"$TARGET_URL"'"],
       "scanner_id": "'"$SCANNER_ID"'",
       "schedule": {
         "enabled": true,
         "starttime": "20260328T220000",
         "timezone": "Europe/Warsaw",
         "rrule": "FREQ=MONTHLY;INTERVAL=1;BYDAY=SA"
       },
"notifications": {
         "emails": ["'"$NOTIFICATION_EMAIL"'"]
        }
     }' | jq
