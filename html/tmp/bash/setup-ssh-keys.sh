#!/bin/bash
# Setup SSH keys for RouterOS router

ROUTER_IP="10.30.30.10:2222"
ROUTER_USER="mikro_bak"
KEY_NAME="mikro_bak_rsa"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Check/create .ssh directory
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi

# Generate SSH key if it doesn't exist
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "routeros-$ROUTER_IP"
fi

# Upload and import key on router
scp "$KEY_PATH.pub" "ssh://$ROUTER_USER@$ROUTER_IP":/
ssh "ssh://$ROUTER_USER@$ROUTER_IP" "/user ssh-keys import public-key-file=$KEY_NAME.pub user=$ROUTER_USER"

# Verify key works
if ! ssh -i "$KEY_PATH" -o PasswordAuthentication=no "$ROUTER_USER@$ROUTER_IP" "/system identity print" >/dev/null 2>&1; then
    echo "Error: SSH key authentication failed"
    exit 1
fi
