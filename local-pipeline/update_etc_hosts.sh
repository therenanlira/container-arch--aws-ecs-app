#!/usr/bin/env bash

set -euo pipefail

: "${AWS_ENV:?AWS_ENV must be set}"
: "${AWS_REGION:?AWS_REGION must be set}"
: "${PROJECT_NAME:?PROJECT_NAME must be set}"

DOMAIN="app.linuxtips.demo"

DNS_NAME=$(aws elbv2 describe-load-balancers \
  --names "$AWS_ENV--$PROJECT_NAME--lb" \
  --query 'LoadBalancers[0].DNSName' \
  --output text --region "$AWS_REGION" 2>/dev/null) || DNS_NAME=""

if [[ -z "$DNS_NAME" || "$DNS_NAME" == "None" ]]; then
  echo "Load balancer not found, skipping /etc/hosts update for $DOMAIN."
  exit 0
fi

IP=$(dig +short "$DNS_NAME" | head -1)

if [[ -z "$IP" ]]; then
  echo "Could not resolve $DNS_NAME, skipping /etc/hosts update for $DOMAIN."
  exit 0
fi

CURRENT_IP=$(awk -v d="$DOMAIN" '$2 == d { print $1 }' /etc/hosts | head -1)

if [[ "$CURRENT_IP" == "$IP" ]]; then
  echo "/etc/hosts already points $DOMAIN to $IP."
  exit 0
fi

echo "Pointing $DOMAIN to $IP in /etc/hosts (requires sudo)"
{ grep -v "[[:space:]]$DOMAIN\$" /etc/hosts || true; echo "$IP $DOMAIN"; } | sudo tee /etc/hosts > /dev/null
