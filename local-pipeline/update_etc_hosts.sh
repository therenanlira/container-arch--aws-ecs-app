#!/usr/bin/env bash
# Points app.linuxtips.demo at the ALB's current IP in /etc/hosts. Route53
# can't host this domain (it isn't a real registered domain, just used for
# local testing), so it has to be resolved locally — and since ALBs don't
# have a stable IP, this needs to be refreshed whenever the environment
# changes. Requires sudo to write /etc/hosts; a no-op if the IP is already
# current, so it won't prompt on every run.
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
