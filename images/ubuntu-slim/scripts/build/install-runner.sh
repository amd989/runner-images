#!/bin/bash -e
################################################################################
##  File:  install-runner.sh
##  Desc:  Install GitHub Actions Runner agent
################################################################################

source $HELPER_SCRIPTS/install.sh

RUNNER_HOME="/opt/actions-runner"
RUNNER_ARCH=$(dpkg --print-architecture)

case "$RUNNER_ARCH" in
    amd64) RUNNER_ARCH="x64" ;;
    arm64) RUNNER_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $RUNNER_ARCH" && exit 1 ;;
esac

# Get latest runner version
auth_header=""
if [[ -n "$GITHUB_TOKEN" ]]; then
    auth_header="-H \"Authorization: token ${GITHUB_TOKEN}\""
fi

RUNNER_VERSION=$(eval curl -s $auth_header https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo "Installing GitHub Actions Runner v${RUNNER_VERSION} (${RUNNER_ARCH})"

RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_ARCHIVE=$(download_with_retry "$RUNNER_URL")

mkdir -p "$RUNNER_HOME"
tar -xzf "$RUNNER_ARCHIVE" -C "$RUNNER_HOME"
rm "$RUNNER_ARCHIVE"

# Install runner dependencies
"${RUNNER_HOME}/bin/installdependencies.sh"

echo "GitHub Actions Runner v${RUNNER_VERSION} installed to ${RUNNER_HOME}"
