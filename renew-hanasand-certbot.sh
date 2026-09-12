#!/usr/bin/env sh
set -eu

DOCKER_BIN="${DOCKER_BIN:-/usr/bin/docker}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-eirik@hanasand.com}"
CERT_NAME="${CERT_NAME:-}"
MODE="${CERTBOT_RENEW_MODE:-live}"

extra=""
if [ "$MODE" = "dry-run" ]; then
    extra="--dry-run"
elif [ "$MODE" != "live" ]; then
    echo "Unsupported CERTBOT_RENEW_MODE: $MODE" >&2
    exit 2
fi

cert_option=""
if [ -n "$CERT_NAME" ]; then
    cert_option="--cert-name $CERT_NAME"
fi

"$DOCKER_BIN" exec openresty sh -lc "certbot renew $cert_option --no-random-sleep-on-renew --agree-tos --email '$CERTBOT_EMAIL' $extra --deploy-hook '/usr/local/openresty/bin/openresty -t && /usr/local/openresty/bin/openresty -s reload'"
