#!/bin/bash

# Setup SSH Key for GitHub Actions
# This script helps generate and configure SSH keys for the GitHub Actions workflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}SSH Key Setup for GitHub Actions${NC}"
echo "======================================"

# Check if ssh-keygen is available
if ! command -v ssh-keygen &> /dev/null; then
    echo -e "${RED}Error: ssh-keygen is not available${NC}"
    exit 1
fi

# Set default values
KEY_NAME="github-actions-truenas"
KEY_TYPE="rsa"
KEY_BITS="4096"

# Ask for key name
echo -e "${YELLOW}Enter key name (default: ${KEY_NAME}):${NC}"
read -r input_key_name
if [ -n "$input_key_name" ]; then
    KEY_NAME="$input_key_name"
fi

# Generate the SSH key
echo -e "${BLUE}Generating SSH key pair...${NC}"
ssh-keygen -t "$KEY_TYPE" -b "$KEY_BITS" -f "$KEY_NAME" -N "" -C "github-actions@$(hostname)"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSH key pair generated successfully!${NC}"
else
    echo -e "${RED}❌ Failed to generate SSH key pair${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Files generated:${NC}"
echo "  Private key: ${KEY_NAME}"
echo "  Public key:  ${KEY_NAME}.pub"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""

echo -e "${BLUE}1. Add the public key to your TrueNAS Scale server:${NC}"
echo "   Copy the following public key content:"
echo "   ----------------------------------------"
cat "${KEY_NAME}.pub"
echo "   ----------------------------------------"
echo ""
echo "   On your TrueNAS Scale server, add this to ~/.ssh/authorized_keys:"
echo "   $ echo 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys"
echo "   $ chmod 600 ~/.ssh/authorized_keys"
echo ""

echo -e "${BLUE}2. Add the private key to GitHub repository secrets:${NC}"
echo "   a. Go to your GitHub repository"
echo "   b. Navigate to Settings → Secrets and variables → Actions"
echo "   c. Click 'New repository secret'"
echo "   d. Name: TRUENAS_SSH_PRIVATE_KEY"
echo "   e. Value: Copy the entire private key content (see below)"
echo ""
echo "   Private key content to copy:"
echo "   ----------------------------------------"
cat "$KEY_NAME"
echo "   ----------------------------------------"
echo ""

echo -e "${BLUE}3. Additional GitHub secrets to configure:${NC}"
echo "   - TS_OAUTH_CLIENT_ID: Your Tailscale OAuth client ID"
echo "   - TS_OAUTH_SECRET: Your Tailscale OAuth client secret"
echo "   - TRUENAS_SSH_USER: SSH username (e.g., root)"
echo "   - TRUENAS_SSH_PORT: SSH port (optional, defaults to 22)"
echo ""

echo -e "${BLUE}4. Test the SSH connection manually:${NC}"
echo "   $ ssh -i ${KEY_NAME} USERNAME@truenas-scale"
echo ""

echo -e "${YELLOW}Security reminder:${NC}"
echo "   - Store the private key securely"
echo "   - Delete these files after adding to GitHub secrets"
echo "   - Consider rotating keys regularly"
echo ""

echo -e "${GREEN}Setup complete! You can now run the GitHub Actions workflow.${NC}"