#!/bin/bash
# VPS Setup Script for Hello Bot Deployment
# Optimized for Ubuntu 22.04 with 2GB RAM
# Usage: ./scripts/setup_vps.sh

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

log_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Don't run this script as root. Run as regular user with sudo access."
    exit 1
fi

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    log_error "This script requires sudo access. Please run: sudo -v"
    exit 1
fi

echo "🚀 Setting up VPS for Hello Bot deployment..."
echo "Optimized for Ubuntu 22.04 with 2GB RAM"
echo

# 1. Update system packages
log_info "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install essential packages
log_info "Installing essential packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    htop \
    nano \
    ufw \
    fail2ban

# 3. Create swap file (important for 2GB RAM)
log_info "Setting up swap file for memory optimization..."
if [ ! -f /swapfile ]; then
    # Create 2GB swap file
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Make swap permanent
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    # Optimize swap settings for low memory VPS
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    
    log_success "Swap file created (2GB)"
else
    log_info "Swap file already exists"
fi

# 4. Install Docker
log_info "Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Configure Docker daemon for low memory
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "default-ulimits": {
        "memlock": {
            "Name": "memlock",
            "Hard": -1,
            "Soft": -1
        }
    }
}
EOF
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    log_success "Docker installed successfully"
else
    log_info "Docker already installed"
fi

# 5. Create deployment user and directories
log_info "Setting up deployment environment..."

# Create hello-bot user if it doesn't exist
if ! id "hello-bot" &>/dev/null; then
    sudo useradd -m -s /bin/bash hello-bot
    sudo usermod -aG docker hello-bot
    log_success "Created hello-bot user"
else
    log_info "hello-bot user already exists"
fi

# Create deployment directories
sudo mkdir -p /opt/hello-bot
sudo chown hello-bot:hello-bot /opt/hello-bot
sudo chmod 755 /opt/hello-bot

# Create logs directory
sudo mkdir -p /var/log/hello-bot
sudo chown hello-bot:hello-bot /var/log/hello-bot

log_success "Deployment directories created"

# 6. Configure firewall
log_info "Configuring firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow PostgreSQL port only from localhost (security)
sudo ufw allow from 127.0.0.1 to any port 5432

log_success "Firewall configured"

# 7. Configure fail2ban for SSH protection
log_info "Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

log_success "fail2ban configured"

# 8. Set up log rotation for Docker
log_info "Configuring log rotation..."
sudo tee /etc/logrotate.d/docker > /dev/null <<EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# 9. Create systemd service for automatic startup
log_info "Creating systemd service..."
sudo tee /etc/systemd/system/hello-bot.service > /dev/null <<EOF
[Unit]
Description=Hello Bot Telegram Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/hello-bot
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
User=hello-bot
Group=hello-bot

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hello-bot

log_success "Systemd service created"

# 10. Install monitoring tools
log_info "Installing monitoring tools..."
sudo apt-get install -y htop iotop nethogs ncdu

# 11. Create useful aliases and scripts
log_info "Setting up helpful aliases..."
sudo -u hello-bot tee /home/hello-bot/.bashrc_additions > /dev/null <<'EOF'
# Hello Bot deployment aliases
alias hb-logs='cd /opt/hello-bot && docker compose logs -f'
alias hb-status='cd /opt/hello-bot && docker compose ps'
alias hb-restart='cd /opt/hello-bot && docker compose restart'
alias hb-update='cd /opt/hello-bot && docker compose pull && docker compose up -d'
alias hb-clean='docker system prune -f'

# System monitoring
alias meminfo='free -h && echo && ps aux --sort=-%mem | head -10'
alias diskinfo='df -h && echo && du -sh /opt/hello-bot/* 2>/dev/null | sort -hr'

# Load aliases
if [ -f ~/.bashrc_additions ]; then
    source ~/.bashrc_additions
fi
EOF

# Add to main bashrc
echo "source ~/.bashrc_additions" | sudo -u hello-bot tee -a /home/hello-bot/.bashrc

# 12. Performance optimizations
log_info "Applying performance optimizations..."

# Kernel parameters for low memory systems
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF

# Hello Bot optimizations for 2GB RAM
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.overcommit_memory = 1
net.core.somaxconn = 1024
EOF

sudo sysctl -p

# 13. Create health check script
log_info "Creating health check script..."
sudo tee /opt/hello-bot/health_check.sh > /dev/null <<'EOF'
#!/bin/bash
# Health check script for Hello Bot

cd /opt/hello-bot

echo "=== Hello Bot Health Check ==="
echo "Date: $(date)"
echo

# Check if services are running
echo "Service Status:"
docker compose ps

echo
echo "Memory Usage:"
free -h

echo
echo "Disk Usage:"
df -h /

echo
echo "Docker Stats:"
timeout 10 docker stats --no-stream

echo
echo "Recent Logs (last 20 lines):"
docker compose logs --tail=20

# Check if bot is responding
echo
echo "Bot Health Check:"
if docker compose exec -T bot python -c "from app.config import settings; print('✅ Bot configuration OK')" 2>/dev/null; then
    echo "✅ Bot is healthy"
else
    echo "❌ Bot health check failed"
fi
EOF

chmod +x /opt/hello-bot/health_check.sh
sudo chown hello-bot:hello-bot /opt/hello-bot/health_check.sh

# 14. Final system information
echo
echo "🎉 VPS Setup Complete!"
echo
echo "=== System Information ==="
echo "OS: $(lsb_release -d | cut -f2)"
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo "Memory: $(free -h | grep Mem | awk '{print $2 " total, " $7 " available"}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $2 " total, " $4 " available"}')"
echo "Swap: $(free -h | grep Swap | awk '{print $2}')"
echo

echo "=== Next Steps ==="
echo "1. Logout and login again (to apply docker group membership)"
echo "2. Test Docker: docker run hello-world"
echo "3. Copy your project files to /opt/hello-bot/"
echo "4. Set up GitHub Actions with these secrets:"
echo "   - VPS_HOST=74.208.125.51"
echo "   - VPS_USER=hello-bot"
echo "   - VPS_SSH_KEY=<your-private-key>"
echo "   - BOT_TOKEN=<your-bot-token>"
echo "   - DB_PASSWORD=<secure-password>"
echo

echo "=== Useful Commands ==="
echo "Health check: /opt/hello-bot/health_check.sh"
echo "View logs: sudo -u hello-bot hb-logs"
echo "Check status: sudo -u hello-bot hb-status"
echo "System resources: htop"
echo

log_success "VPS is ready for Hello Bot deployment!"

# Reminder to reboot if needed
if [ -f /var/run/reboot-required ]; then
    log_warning "System reboot is recommended to complete the setup"
    echo "Run: sudo reboot"
fi