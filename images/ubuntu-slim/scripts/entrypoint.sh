#!/bin/bash
set -eo pipefail

# Load environment variables from image build
set -a
source /etc/environment
set +a

export RUNNER_ALLOW_RUNASROOT=1

RUNNER_HOME="/opt/actions-runner"

# ─── If no runner config provided, just exec the command (or idle) ───────────

if [ -z "$GITHUB_PAT" ] || [ -z "$GITHUB_OWNER" ]; then
    if [ $# -gt 0 ]; then
        exec "$@"
    else
        echo "No GITHUB_PAT/GITHUB_OWNER set and no command given. Nothing to do."
        exit 0
    fi
fi

# ─── Determine scope (org vs repo) ──────────────────────────────────────────

if [ -n "$GITHUB_REPOSITORY" ]; then
    RUNNER_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}"
    TOKEN_API="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners"
else
    RUNNER_URL="https://github.com/${GITHUB_OWNER}"
    TOKEN_API="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners"
fi

# ─── Generate unique runner name ─────────────────────────────────────────────

RUNNER_SUFFIX=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 8)
RUNNER_NAME="${RUNNER_NAME_PREFIX:-runner}-${RUNNER_SUFFIX}"

# ─── Token helpers ───────────────────────────────────────────────────────────

get_registration_token() {
    local token
    token=$(curl -sf -X POST \
        -H "Authorization: token ${GITHUB_PAT}" \
        -H "Accept: application/vnd.github.v3+json" \
        "${TOKEN_API}/registration-token" | jq -r '.token')

    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "Error: failed to get registration token. Check GITHUB_PAT permissions." >&2
        exit 1
    fi
    echo "$token"
}

get_remove_token() {
    curl -sf -X POST \
        -H "Authorization: token ${GITHUB_PAT}" \
        -H "Accept: application/vnd.github.v3+json" \
        "${TOKEN_API}/remove-token" | jq -r '.token'
}

# ─── Cleanup on exit ────────────────────────────────────────────────────────

cleanup() {
    echo "Removing runner registration..."
    local remove_token
    remove_token=$(get_remove_token 2>/dev/null) || true
    if [ -n "$remove_token" ] && [ "$remove_token" != "null" ]; then
        cd "$RUNNER_HOME"
        ./config.sh remove --token "$remove_token" 2>/dev/null || true
    fi
}
trap cleanup EXIT SIGTERM SIGINT

# ─── Configure ───────────────────────────────────────────────────────────────

cd "$RUNNER_HOME"

if [ -f ".runner" ]; then
    echo "Runner already configured, reusing existing registration."
    RUNNER_NAME=$(jq -r '.agentName' .runner)
else
    echo "Registering runner '${RUNNER_NAME}' for ${RUNNER_URL}..."
    REG_TOKEN=$(get_registration_token)

    ./config.sh \
        --url "$RUNNER_URL" \
        --token "$REG_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "${RUNNER_LABELS:-self-hosted,linux,x64,docker}" \
        --runnergroup "${RUNNER_GROUP:-Default}" \
        --work "${RUNNER_WORKDIR:-_work}" \
        --unattended \
        --replace
fi

# ─── Run ─────────────────────────────────────────────────────────────────────

echo "Starting runner '${RUNNER_NAME}'..."
exec ./run.sh
