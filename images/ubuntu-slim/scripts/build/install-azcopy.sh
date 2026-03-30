#!/bin/bash -e
################################################################################
##  File:  install-azcopy.sh
##  Desc:  Install AzCopy
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install AzCopy10
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  AZCOPY_URL="https://aka.ms/downloadazcopy-v10-linux" ;;
    aarch64) AZCOPY_URL="https://aka.ms/downloadazcopy-v10-linux-arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

archive_path=$(download_with_retry "$AZCOPY_URL")
tar xzf "$archive_path" --strip-components=1 -C /tmp
install /tmp/azcopy /usr/local/bin/azcopy

# Create azcopy 10 alias for backward compatibility
ln -sf /usr/local/bin/azcopy /usr/local/bin/azcopy10
