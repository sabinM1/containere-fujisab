#!/bin/bash

# --- CONFIGURATION ---
# Source paths
VW_DATA_DIR="/home/user/containere/vaultwarden/"
DOCKER_COMPOSE_DIR="/home/user/containere/vaultwarden"
BACKUP_STAGING_DIR="/home/user/vw-backups-staging"
CMD_DOCKER="/usr/bin/docker"
CMD_ZIP="/usr/bin/zip"
CMD_CURL="/usr/bin/curl"
CMD_DATE="/usr/bin/date"
CMD_MKDIR="/usr/bin/mkdir"
CMD_DIRNAME="/usr/bin/dirname"
CMD_BASENAME="/usr/bin/basename"
CMD_DU="/usr/bin/du"
CMD_CUT="/usr/bin/cut"
CMD_CAT="/usr/bin/cat"
CMD_HOSTNAME="/usr/bin/hostname"

# Remote details (Tailscale)
REMOTE_USER="CHANGEME"
REMOTE_HOST="CHANGEME"
REMOTE_DIR="/home/user/vwbak"
SSH_KEY="/home/user/.ssh/vw_backup_key"

# Discord Webhook
DISCORD_WEBHOOK="CHANGEME"

# Filename
DATESTAMP=$($CMD_DATE +%m-%d-%Y)
FILENAME="vw-backup-${DATESTAMP}.zip"
START_TIME=$($CMD_DATE +%s)

# --- FUNCTIONS ---

send_discord() {
    local status="$1" # "SUCCESS" or "FAILURE"
    local message="$2"
    local color=""
    local title=""

    if [ "$status" == "SUCCESS" ]; then
        color=3066993  # Green
        title="✅ Vaultwarden Backup Successful"
    else
        color=15158332 # Red
        title="❌ Vaultwarden Backup FAILED"
    fi

    # JSON Payload for Discord Embed
    generate_post_data() {
      $CMD_CAT <<EOF
{
  "username": "Backup Bot",
  "embeds": [{
    "title": "$title",
    "description": "$message",
    "color": $color,
    "fields": [
      { "name": "File", "value": "$FILENAME", "inline": true },
      { "name": "Host", "value": "$($CMD_HOSTNAME)", "inline": true },
      { "name": "Target", "value": "$REMOTE_HOST", "inline": true }
    ],
    "footer": { "text": "$($CMD_DATE)" }
  }]
}
EOF
    }

    $CMD_CURL -H "Content-Type: application/json" \
         -X POST \
         -d "$(generate_post_data)" \
         "$DISCORD_WEBHOOK"
}

# --- MAIN LOGIC ---

# Create staging dir if missing
$CMD_MKDIR -p "$BACKUP_STAGING_DIR"

# 1. Stop Vaultwarden
echo "Stopping Vaultwarden..."
cd "$DOCKER_COMPOSE_DIR" || { send_discord "FAILURE" "Could not find Docker dir: $DOCKER_COMPOSE_DIR"; exit 1; }
sudo $CMD_DOCKER compose down

# 2. Archive Data
echo "Zipping data..."
PARENT_DIR=$($CMD_DIRNAME "$VW_DATA_DIR")
BASE_NAME=$($CMD_BASENAME "$VW_DATA_DIR")

cd "$PARENT_DIR" || { send_discord "FAILURE" "Could not find Parent dir: $PARENT_DIR"; exit 1; }

if ! sudo $CMD_ZIP -9 -r "${BACKUP_STAGING_DIR}/${FILENAME}" "$BASE_NAME"; then
    # Restart if zip fails
    cd "$DOCKER_COMPOSE_DIR"
    sudo $CMD_DOCKER compose up -d
    send_discord "FAILURE" "Zip command failed"
    exit 1
fi

# 3. Start Vaultwarden (ASAP)
echo "Starting Vaultwarden..."
cd "$DOCKER_COMPOSE_DIR"
sudo $CMD_DOCKER compose up -d

# 4. Transfer to Remote Server
echo "Transferring backup to ${REMOTE_HOST}..."
if scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "${BACKUP_STAGING_DIR}/${FILENAME}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/${FILENAME}"; then
    
    # Calculate duration
    END_TIME=$($CMD_DATE +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # Get file size
    FILE_SIZE=$($CMD_DU -h "${BACKUP_STAGING_DIR}/${FILENAME}" | $CMD_CUT -f1)

    echo "Backup successful!"
    send_discord "SUCCESS" "Backup transferred successfully.\n**Size:** $FILE_SIZE\n**Duration:** ${DURATION}s"
    
    # Optional: Delete local zip
    # rm "${BACKUP_STAGING_DIR}/${FILENAME}"
else
    echo "Backup transfer FAILED."
    send_discord "FAILURE" "SCP transfer failed. Check remote host connection."
    exit 1
fi
