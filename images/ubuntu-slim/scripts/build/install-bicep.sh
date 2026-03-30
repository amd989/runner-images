#!/bin/bash -e
################################################################################
##  File:  install-bicep.sh
##  Desc:  Install bicep cli
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install Bicep CLI
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  BICEP_ARCH="x64" ;;
    aarch64) BICEP_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

download_url=$(resolve_github_release_asset_url "Azure/bicep" "endswith(\"bicep-linux-${BICEP_ARCH}\")" "latest")
bicep_binary_path=$(download_with_retry "${download_url}")

# Mark it as executable
install "$bicep_binary_path" /usr/local/bin/bicep
