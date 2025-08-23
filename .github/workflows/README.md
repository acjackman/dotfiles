# GitHub Actions SSH Connectivity Test

This directory contains GitHub Actions workflows for testing SSH connectivity to infrastructure servers.

## SSH Connectivity Test to TrueNAS Scale

The `ssh-connectivity-test.yml` workflow tests SSH connectivity from GitHub Actions to a TrueNAS Scale server using Tailscale for secure networking.

### Features

- **Automated Testing**: Runs on push, pull requests, manual trigger, and daily schedule
- **Tailscale Integration**: Uses Tailscale for secure network access
- **Comprehensive Testing**: Tests ping, SSH connection, and basic system commands
- **Deployment Readiness**: Validates file operations and service management capabilities
- **Detailed Reporting**: Generates connectivity reports and uploads them as artifacts

### Required GitHub Secrets

Before running this workflow, you need to configure the following secrets in your GitHub repository:

#### Tailscale Secrets
- `TS_OAUTH_CLIENT_ID`: Tailscale OAuth client ID
- `TS_OAUTH_SECRET`: Tailscale OAuth client secret

#### SSH Secrets
- `TRUENAS_SSH_PRIVATE_KEY`: Private SSH key for connecting to TrueNAS Scale
- `TRUENAS_SSH_USER`: SSH username for TrueNAS Scale (e.g., `root` or your admin user)
- `TRUENAS_SSH_PORT`: SSH port for TrueNAS Scale (optional, defaults to 22)

### Setup Instructions

#### 1. Tailscale Setup

1. Create a Tailscale account and set up your tailnet
2. Install Tailscale on your TrueNAS Scale server:
   ```bash
   # On TrueNAS Scale, you can install Tailscale via the Apps interface
   # or manually via command line if available
   ```
3. Create OAuth credentials for GitHub Actions:
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
   - Create a new OAuth client
   - Set appropriate scopes and tags (the workflow uses `tag:ci`)
   - Copy the client ID and secret to GitHub secrets

#### 2. SSH Key Setup

1. Generate an SSH key pair for GitHub Actions:
   ```bash
   ssh-keygen -t rsa -b 4096 -f github-actions-key -N ""
   ```

2. Add the public key to your TrueNAS Scale server:
   ```bash
   # Copy the public key to the server
   ssh-copy-id -i github-actions-key.pub user@truenas-scale
   
   # Or manually add to ~/.ssh/authorized_keys
   ```

3. Add the private key to GitHub secrets as `TRUENAS_SSH_PRIVATE_KEY`

#### 3. TrueNAS Scale Configuration

Ensure your TrueNAS Scale server:
- Has Tailscale installed and connected to your tailnet
- Has SSH enabled and accessible
- Has the hostname `truenas-scale` in Tailscale (or update the workflow accordingly)
- Has the SSH user configured with appropriate permissions

#### 4. GitHub Repository Configuration

1. Go to your repository settings → Secrets and variables → Actions
2. Add all the required secrets listed above
3. Ensure the repository has Actions enabled

### Workflow Triggers

The workflow runs on:
- **Push** to main/master branches
- **Pull requests** to main/master branches
- **Manual trigger** via GitHub Actions UI
- **Daily schedule** at 6 AM UTC for monitoring

### Test Coverage

The workflow performs the following tests:

1. **Tailscale Connectivity**
   - Establishes Tailscale connection
   - Verifies TrueNAS Scale is reachable via Tailscale
   - Tests ping connectivity

2. **SSH Connectivity**
   - Tests SSH connection establishment
   - Verifies authentication
   - Tests basic command execution

3. **System Information**
   - Retrieves hostname, OS, uptime
   - Checks disk and memory usage
   - Verifies TrueNAS Scale services

4. **Deployment Readiness**
   - Tests file system operations
   - Checks Docker availability (if installed)
   - Verifies systemctl functionality

### Troubleshooting

#### Common Issues

1. **Tailscale Connection Failed**
   - Verify OAuth credentials are correct
   - Check that TrueNAS Scale is connected to Tailscale
   - Ensure the hostname matches in Tailscale

2. **SSH Connection Failed**
   - Verify SSH key is correct and properly formatted
   - Check SSH user permissions
   - Ensure SSH service is running on TrueNAS Scale

3. **Permission Denied**
   - Verify the SSH user has appropriate sudo/admin privileges
   - Check file system permissions

#### Viewing Results

1. Go to the Actions tab in your GitHub repository
2. Click on the latest workflow run
3. Review the step-by-step logs
4. Download the connectivity report artifact for detailed information

### Security Considerations

- SSH keys should be dedicated to GitHub Actions and rotated regularly
- Tailscale OAuth credentials should have minimal required permissions
- The workflow uses `StrictHostKeyChecking no` for automation - ensure your network is secure
- Consider using environment-specific secrets for different deployment targets

### Customization

To adapt this workflow for other servers:

1. Update the hostname in the workflow file
2. Modify the test commands based on your server type
3. Adjust the SSH configuration as needed
4. Update the documentation accordingly