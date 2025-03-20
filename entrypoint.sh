#!/bin/ash -l

set -e

if [[ ! -d /etc/letsencrypt/live ]]; then
    echo "Please ensure that /etc/letsencrypt is persistent! Or is this the first run?"
fi
if [[ "${CLOUDFLARE_API_TOKEN}" == "" ]]; then
    echo "CLOUDFLARE_API_TOKEN not set. This is required."
    exit 2
fi
if [[ "${DOMAIN}" == "" ]]; then
    echo "DOMAIN variable not set."
    exit 3
fi
if [[ "${EMAIL}" == "" ]]; then
    echo "EMAIL variable not set."
    exit 4
fi

# Check if DRY_RUN is set
DRY_RUN_FLAG=""
if [[ "${DRY_RUN}" == "1" ]]; then
    echo "DRY_RUN is set to 1. Will perform a dry run without saving certificates."
    DRY_RUN_FLAG="--dry-run"
fi

echo "$(date) starting certbot scripts"

run_as_user() {
    if [[ -n "$CERTBOT_USER" ]]; then
        echo "running as default user certbot"
        sudo -u $CERTBOT_USER "$@"
    else
        echo "running as custom user $USER"
        "$@"
    fi
}

# Determine user context and set appropriate variables
if [[ "$(whoami)" == "root" ]]; then
    HOME_DIR=$(getent passwd "certbot" | cut -d: -f6)
    CREDENTIAL_FILE="$HOME_DIR/cloudflare.ini"
    CERTBOT_USER="certbot"

    echo "Setting up environment for certbot user, home $HOME_DIR"
    chown -R certbot:certbot /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt /certs
else
    cd ~
    CREDENTIAL_FILE=~/cloudflare.ini
    CERTBOT_USER=""
    echo "Setting up environment for custom user $USER, home $(pwd)"
fi

# Create credentials file
echo "dns_cloudflare_api_key=${CLOUDFLARE_API_TOKEN}" > "$CREDENTIAL_FILE"
echo "dns_cloudflare_email=${EMAIL}" >> "$CREDENTIAL_FILE"
chmod 600 "$CREDENTIAL_FILE"

# Set ownership if running as root
[[ -n "$CERTBOT_USER" ]] && chown $CERTBOT_USER:$CERTBOT_USER "$CREDENTIAL_FILE"

# Run certbot
echo "$(date) running certbot"
run_as_user certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CREDENTIAL_FILE" \
    -d ${DOMAIN} \
    --non-interactive \
    --agree-tos \
    ${DRY_RUN_FLAG}

# Run renewal script
echo "$(date) running renewal script"
run_as_user /renew.sh

# Run crond
echo "$(date) running crond in forefront"
run_as_user crond -l 2 -f
