#!/bin/bash
# Helper script to deploy and setup VPS
# Usage: ./scripts/deploy_to_vps.sh

set -euo pipefail

VPS_HOST="74.208.125.51"
VPS_USER="mrbzzz"

echo "🚀 Deploying Hello Bot to VPS..."
echo "VPS: $VPS_USER@$VPS_HOST"
echo

# 1. Copy setup script to VPS
echo "📤 Copying setup script to VPS..."
scp scripts/setup_vps.sh $VPS_USER@$VPS_HOST:/tmp/

# 2. Connect to VPS and run setup
echo "🔧 Connecting to VPS to run setup..."
echo "Note: You'll need to enter your VPS password and confirm sudo access"
echo "This will open an interactive SSH session..."
echo

# Use interactive SSH to ensure sudo works properly
ssh -tt $VPS_USER@$VPS_HOST << 'EOF'
echo "🎯 Connected to VPS successfully!"
echo "Current directory: $(pwd)"
echo "User: $(whoami)"
echo

# Make script executable
chmod +x /tmp/setup_vps.sh

echo "🚀 Starting VPS setup..."
echo "This will install Docker, configure system, and optimize for 2GB RAM"
echo

# Run the setup script with proper sudo handling
echo "Please enter your sudo password when prompted..."
sudo /tmp/setup_vps.sh

echo
echo "✅ VPS setup completed!"
echo "🔍 Checking Docker installation..."
docker --version
docker compose version

echo
echo "📊 System status after setup:"
free -h
df -h /

echo
echo "🎉 VPS is ready for Hello Bot deployment!"
echo "Next steps:"
echo "1. Set up GitHub Secrets"
echo "2. Push to main branch to trigger deployment"
echo "3. Monitor deployment in GitHub Actions"
EOF

echo
echo "✅ VPS setup process completed!"
echo "Check the output above for any errors."