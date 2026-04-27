#!/bin/bash
set -euo pipefail

MICROBIN_DATA_DIR="${MICROBIN_DATA_DIR:?MICROBIN_DATA_DIR not set}"
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:?DISCORD_WEBHOOK_URL not set}"

DB="$MICROBIN_DATA_DIR/database.sqlite"

SIZE_BYTES=$(du -sb "$MICROBIN_DATA_DIR" 2>/dev/null | cut -f1 || echo 0)
SIZE_HUMAN=$(numfmt --to=iec --suffix=B "$SIZE_BYTES")

TOTAL_PASTES=$(sqlite3 "file:$DB?mode=ro" "SELECT COUNT(*) FROM pasta;" 2>/dev/null || echo 0)
NEW_PASTES=$(sqlite3 "file:$DB?mode=ro" "SELECT COUNT(*) FROM pasta WHERE created > strftime('%s','now','-1 day');" 2>/dev/null || echo 0)

PAYLOAD=$(jq -n \
  --arg size "$SIZE_HUMAN" --arg bytes "$SIZE_BYTES" \
  --arg total "$TOTAL_PASTES" --arg new "$NEW_PASTES" \
  --arg host "$(hostname)" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    username: "Microbin Monitor",
    embeds: [{
      title: "📦 Microbin Daily Report",
      color: 5814783,
      fields: [
        {name: "Total Size",   value: ($size + " (" + $bytes + " bytes)"), inline: true},
        {name: "Total Pastes", value: $total, inline: true},
        {name: "New in 24h",   value: $new,   inline: true}
      ],
      footer: {text: $host},
      timestamp: $ts
    }]
  }')

curl -sf -X POST "$DISCORD_WEBHOOK_URL" \
  -H "Content-Type: application/json" -d "$PAYLOAD" > /dev/null
