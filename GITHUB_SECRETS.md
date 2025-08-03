# GitHub Secrets Configuration

This document explains how to configure GitHub Secrets for Hello Bot deployment.

## Required Secrets

Navigate to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### 1. VPS Connection Secrets

#### `VPS_HOST`

- **Description**: IP address or domain name of your VPS
- **Example**: `123.456.789.123` or `your-server.example.com`
- **How to get**: Your VPS provider dashboard or server details

#### `VPS_USER`

- **Description**: Username for SSH connection to VPS
- **Example**: `ubuntu`, `root`, or your custom username
- **How to get**: Check with your VPS provider or use the user you created

#### `VPS_SSH_KEY`

- **Description**: Private SSH key for authentication
- **Format**: Full private key including headers
- **How to generate**:

  ```bash
  # On your local machine, generate SSH key pair
  ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/hello-bot-deploy

  # Copy public key to VPS
  ssh-copy-id -i ~/.ssh/hello-bot-deploy.pub your-user@your-vps-ip

  # Copy private key content for GitHub secret
  cat ~/.ssh/hello-bot-deploy
  ```

- **Example format**:
  ```
  -----BEGIN OPENSSH PRIVATE KEY-----
  b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
  ... (full private key content) ...
  -----END OPENSSH PRIVATE KEY-----
  ```

#### `VPS_PORT` (Optional)

- **Description**: SSH port number
- **Default**: `22`
- **Example**: `22`, `2222`, `2200`
- **Note**: Only set this if you're using a non-standard SSH port

### 2. Application Secrets

#### `BOT_TOKEN`

- **Description**: Telegram Bot API token
- **Example**: `1234567890:ABCDEFGHIJKLMNOPQRSTUVWXYZ-abcdefgh`
- **How to get**:
  1. Message [@BotFather](https://t.me/botfather) on Telegram
  2. Send `/newbot` or use existing bot
  3. Copy the token provided

#### `DB_PASSWORD`

- **Description**: PostgreSQL database password
- **Example**: `your-secure-db-password-123`
- **Requirements**:
  - Use a strong, unique password
  - At least 12 characters recommended
  - Include letters, numbers, and symbols

## Environment Variables (Optional)

You can also set these as secrets if you want to override defaults:

#### `ENVIRONMENT`

- **Description**: Deployment environment
- **Default**: `production`
- **Options**: `production`, `staging`

## Security Best Practices

### SSH Key Security

- ✅ **Generate dedicated keys** for deployment (don't reuse personal keys)
- ✅ **Use Ed25519 keys** for better security
- ✅ **Restrict key access** on VPS if possible
- ❌ **Never share or commit** private keys

### Password Security

- ✅ **Use strong, unique passwords** for database
- ✅ **Store passwords securely** (use password manager)
- ✅ **Rotate passwords regularly**
- ❌ **Never use default or simple passwords**

### VPS Security

- ✅ **Disable password authentication** for SSH (use keys only)
- ✅ **Enable firewall** (UFW recommended)
- ✅ **Keep system updated** regularly
- ✅ **Monitor access logs**

## Testing Secrets

Before setting up secrets, test your VPS connection:

```bash
# Test SSH connection
ssh -i ~/.ssh/hello-bot-deploy your-user@your-vps-ip

# Test bot token
curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getMe"
```

## Verification Steps

1. **Run VPS test script**:

   ```bash
   # Copy script to your VPS
   scp scripts/test_vps.sh 74.208.125.51:~/

   # SSH to your VPS and run the test
   ssh 74.208.125.51
   chmod +x ~/tmp/test_vps.sh
   cd ~/tmp
   ./test_vps.sh
   ```

2. **Test GitHub Actions** (dry run):

   - Push a small change to trigger workflow
   - Monitor the deployment process
   - Check logs for any issues

3. **Verify deployment**:
   ```bash
   # On VPS after deployment
   cd /opt/hello-bot
   docker compose ps
   docker compose logs bot
   ```

## Common Issues

### SSH Connection Failed

- ✅ Check VPS_HOST is correct IP/domain
- ✅ Verify VPS_USER exists on server
- ✅ Ensure SSH key is properly formatted
- ✅ Check VPS_PORT if using non-standard port

### Bot Token Invalid

- ✅ Verify token format (should start with numbers)
- ✅ Test token with Telegram API
- ✅ Check for extra spaces or characters

### Database Connection Failed

- ✅ Ensure DB_PASSWORD is secure
- ✅ Check PostgreSQL is running
- ✅ Verify network connectivity

## Support

If you encounter issues:

1. Check GitHub Actions logs for detailed error messages
2. SSH to VPS and check Docker logs: `docker compose logs`
3. Verify all secrets are correctly set and formatted
4. Run the VPS test script to identify configuration issues

## Example Secret Values

**Note**: These are examples only - never use these exact values!

| Secret        | Example Value                       |
| ------------- | ----------------------------------- |
| `VPS_HOST`    | `203.0.113.1`                       |
| `VPS_USER`    | `ubuntu`                            |
| `VPS_PORT`    | `22`                                |
| `BOT_TOKEN`   | `1234567890:ABCDEF-abcdef123456789` |
| `DB_PASSWORD` | `MySecurePassword123!@#`            |

Remember to use your own secure values!
