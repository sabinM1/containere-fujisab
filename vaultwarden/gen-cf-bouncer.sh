#!/bin/bash
# Run once after setting all values in .env to generate crowdsec/cf-bouncer.yaml
# Usage: bash gen-cf-bouncer.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found at $ENV_FILE"
  exit 1
fi

source "$ENV_FILE"

: "${CROWDSEC_BOUNCER_KEY:?CROWDSEC_BOUNCER_KEY not set in .env}"
: "${CF_ACCOUNT_ID:?CF_ACCOUNT_ID not set in .env}"
: "${CF_API_TOKEN:?CF_API_TOKEN not set in .env}"
: "${CF_ZONE_ID:?CF_ZONE_ID not set in .env}"

mkdir -p "$SCRIPT_DIR/crowdsec"

cat > "$SCRIPT_DIR/crowdsec/cf-bouncer.yaml" << YAML
crowdsec_lapi_url: http://crowdsec-vault:8080/
crowdsec_lapi_key: ${CROWDSEC_BOUNCER_KEY}
crowdsec_update_frequency: 60s

# Include both local decisions AND CAPI (community blocklist)
# Local decisions are prioritized because they're newer and pushed first
only_include_decisions_from:
  - "cscli"      # Manual bans via cscli
  - "crowdsec"   # Local scenario detections
  - "CAPI"       # Community blocklist (fills remaining capacity)

# Only sync web/security-relevant scenarios
# This filters out noise and keeps the list focused on actual threats
include_scenarios_containing:
  - "http"
  - "web"
  - "appsec"
  - "ssh"
  - "bf"         # Brute force scenarios
  - "scan"
  - "exploit"

# Exclude low-priority or noisy scenarios that waste list capacity
exclude_scenarios_containing:
  - "dns"        # DNS-based scenarios often have high volume
  - "spam"       # Spam scenarios can be very noisy

cloudflare_config:
  accounts:
    - id: ${CF_ACCOUNT_ID}
      token: ${CF_API_TOKEN}
      ip_list_prefix: crowdsec
      default_action: block
      # Hard cap at 9500 to stay under Cloudflare's 10k limit
      # When limit is reached, newest decisions (local) replace oldest (community)
      total_ip_list_capacity: 9500
      zones:
        - zone_id: ${CF_ZONE_ID}
          actions:
            - block
  update_frequency: 96h
daemon: false
log_mode: stdout
log_level: info
prometheus:
  enabled: false
YAML

echo "✅ crowdsec/cf-bouncer.yaml generated successfully"
echo "⚠️  This file contains secrets — do NOT commit it to git"
echo "ℹ️  Configured to prioritize local decisions over community blocklist"
echo "ℹ️  When 9500 IP limit is reached, newest bans (local) replace oldest (community)"
