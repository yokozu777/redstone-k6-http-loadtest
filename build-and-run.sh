#!/usr/bin/env bash
# Profile: default, light, heavy, or spike. Pass it as the first argument or as PROFILE.
# TARGET_HOST, ENDPOINTS, INSTALL_LOCAL_CERT (true|false), and REMOTE_CA_URL come from the environment.
set -euo pipefail

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 [default|light|heavy|spike]" >&2
    echo "  TARGET_HOST          host to test (default: https://change-me.example/)" >&2
    echo "  ENDPOINTS            comma-separated paths (default: /)" >&2
    echo "  INSTALL_LOCAL_CERT   true installs certs/*.crt (default: false)" >&2
    echo "  REMOTE_CA_URL        optional CA URL downloaded with TLS verification skipped" >&2
    exit 1
}

if [ "$#" -gt 1 ]; then
    usage
fi

PROFILE="${1:-${PROFILE:-default}}"
TARGET_HOST="${TARGET_HOST:-https://change-me.example/}"
ENDPOINTS="${ENDPOINTS:-/}"
INSTALL_LOCAL_CERT="${INSTALL_LOCAL_CERT:-false}"
REMOTE_CA_URL="${REMOTE_CA_URL:-}"

case "$INSTALL_LOCAL_CERT" in
    true|false) ;;
    *)
        echo "INSTALL_LOCAL_CERT must be true or false" >&2
        exit 1
        ;;
esac

run_k6() {
    docker run --rm -it \
        --user "$(id -u):$(id -g)" \
        -e "TARGET_HOST=$TARGET_HOST" \
        -e "ENDPOINTS=$ENDPOINTS" \
        -v "$PWD/results:/app/results" \
        ph-loadtest \
        -c "/app/config/$config" run --out "json=/app/results/$result" "$@" /app/loadtest.js
}

case "$PROFILE" in
    default)
        config="default.json"
        result="results.json"
        k6_cmd=(run_k6 --vus 200 --duration 10m)
        ;;
    light)
        config="light-load.json"
        result="light.json"
        k6_cmd=(run_k6)
        ;;
    heavy)
        config="heavy-load.json"
        result="heavy.json"
        k6_cmd=(run_k6)
        ;;
    spike)
        config="spike-test.json"
        result="spike.json"
        k6_cmd=(run_k6)
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Unknown profile: $PROFILE" >&2
        usage
        ;;
esac

mkdir -p results

echo "Building the image (INSTALL_LOCAL_CERT=$INSTALL_LOCAL_CERT)..."
docker build \
    --build-arg "INSTALL_LOCAL_CERT=$INSTALL_LOCAL_CERT" \
    --build-arg "REMOTE_CA_URL=$REMOTE_CA_URL" \
    -t ph-loadtest .

echo "Starting profile '$PROFILE' against $TARGET_HOST"
echo "Paths: $ENDPOINTS"
echo "Results: results/$result"
"${k6_cmd[@]}"

echo "Profile '$PROFILE' finished. Results are in results/$result"
