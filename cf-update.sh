#!/bin/bash

# Load environment variables from .env file
if [ -f /opt/dnsupdate/.env ]; then
  source /opt/dnsupdate/.env
else
  echo "Error: .env file not found." >> /var/log/dns_update.log
  exit 1
fi

# Look up IP and date/time
myip=$(/usr/sbin/ip addr show "$INTERFACE" | /usr/bin/grep 'inet ' | /usr/bin/awk '{print $2}' | /usr/bin/cut -d/ -f1)
if [ -z "$myip" ]; then
  echo "Error: Could not find IP address for interface $INTERFACE" >> /var/log/dns_update.log
  exit 1
fi
currdate=$(/usr/bin/date -Iminutes)

# Get current IP from Cloudflare
response=$(/usr/bin/curl --silent --request GET \
  --url "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $API")

# Extract current IP from response
current=$(echo "$response" | /usr/bin/python3 -c "
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

if [ $? -ne 0 ]; then
  echo "Error extracting current IP from response" >> /var/log/dns_update.log
  exit 1
fi

# Only update if changed
if [ "$current" != "$myip" ]; then
  # Update record
  update_response=$(/usr/bin/curl --silent --request PUT \
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

  if [ $? -eq 0 ]; then
    echo "[$(date)] Updated record from $current to $myip" >> /var/log/dns_update.log
  else
    echo "[$(date)] Failed to update record" >> /var/log/dns_update.log
  fi
else
  echo "[$(date)] No update needed. Current IP: $current" >> /var/log/dns_update.log
fi
