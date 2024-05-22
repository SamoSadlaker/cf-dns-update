#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
fi

# Look up IP and date/time
myip=$(ip addr show "$INTERFACE" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
currdate=$(date -Iminutes)

# Get current IP from Cloudflare
response=$(curl --silent --request GET \
  --url "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $API")

# Extract current IP from response
current=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    if 'result' in data:
        print(data['result']['content'])
    else:
        print('Error: Key result not found', file=sys.stderr)
        sys.exit(1)
except json.JSONDecodeError as e:
    print(f'Error decoding JSON: {e}', file=sys.stderr)
    sys.exit(1)
")

# Only update if changed
if [ "$current" != "$myip" ]; then
  # Update record
  update_response=$(curl --silent --request PUT \
    --url "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $API" \
    --data '{
      "content": "'"$myip"'",
      "name": "'"$DOMAIN"'",
      "proxied": '"$PROXIED"',
      "type": "A",
      "comment": "Automatically updated '"$currdate"'",
      "ttl": 3600
    }')
  echo "Updated"
fi
