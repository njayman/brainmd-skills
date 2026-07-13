#!/usr/bin/env bash
# Get a session token from a brain.md instance
# Usage: ./get-session-token.sh <base_url> <password>
# Example: ./get-session-token.sh https://brain.example.com mypassword

set -euo pipefail

BASE_URL="${1:?Usage: $0 <base_url> <password>}"
PASSWORD="${2:?Usage: $0 <base_url> <password>}"

TOKEN=$(curl -s -X POST "${BASE_URL}/api/auth/login" \
  -H 'content-type: application/json' \
  -d "{\"password\":\"${PASSWORD}\"}" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Error: Failed to get token. Check URL and password." >&2
  exit 1
fi

echo "$TOKEN"
