#!/bin/bash -e
################################################################################
##  File:  install-aws-tools.sh
##  Desc:  Install the AWS CLI, Session Manager plugin for the AWS CLI, and AWS SAM CLI
##  Supply chain security: AWS SAM CLI - checksum validation
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  AWS_ARCH="x86_64"; SM_ARCH="ubuntu_64bit"; SAM_ARCH="x86_64" ;;
    aarch64) AWS_ARCH="aarch64"; SM_ARCH="ubuntu_arm64"; SAM_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

awscliv2_archive_path=$(download_with_retry "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip")
unzip -qq "$awscliv2_archive_path" -d /tmp/installers/
/tmp/installers/aws/install -i /usr/local/aws-cli -b /usr/local/bin

smplugin_deb_path=$(download_with_retry "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${SM_ARCH}/session-manager-plugin.deb")
apt-get install "$smplugin_deb_path"

# Download the latest aws sam cli release
aws_sam_cli_archive_name="aws-sam-cli-linux-${SAM_ARCH}.zip"
sam_cli_download_url=$(resolve_github_release_asset_url "aws/aws-sam-cli" "endswith(\"$aws_sam_cli_archive_name\")" "latest")
aws_sam_cli_archive_path=$(download_with_retry "$sam_cli_download_url")

# Supply chain security - AWS SAM CLI
aws_sam_cli_hash=$(get_checksum_from_github_release "aws/aws-sam-cli" "${aws_sam_cli_archive_name}.. " "latest" "SHA256")
use_checksum_comparison "$aws_sam_cli_archive_path" "$aws_sam_cli_hash"

# Install the latest aws sam cli release
mkdir -p /tmp/installers/aws-sam-cli
unzip "$aws_sam_cli_archive_path" -d /tmp/installers/aws-sam-cli
/tmp/installers/aws-sam-cli/install -i /usr/local/aws-sam-cli -b /usr/local/bin
