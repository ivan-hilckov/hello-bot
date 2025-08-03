#!/bin/bash
# VPS Analysis Script for optimal GitHub Actions deployment
# Usage: ./scripts/test_log_vps.sh

set -euo pipefail

echo "=== VPS DEPLOYMENT ANALYSIS ==="
echo "Timestamp: $(date)"
echo "Script version: 1.0"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# System Information
echo "--- SYSTEM INFO ---"
echo "OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d '"' -f 2 || echo 'Unknown')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo "Current User: $(whoami)"
echo "Home Directory: $HOME"
echo

# Hardware Resources
echo "--- HARDWARE RESOURCES ---"
CPU_CORES=$(nproc)
echo "CPU Cores: $CPU_CORES"
echo "CPU Info: $(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d ':' -f 2 | xargs || echo 'N/A')"

# Memory information
if command -v free >/dev/null 2>&1; then
    RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    RAM_AVAILABLE=$(free -h | grep Mem | awk '{print $7}')
    echo "RAM Total: $RAM_TOTAL"
    echo "RAM Available: $RAM_AVAILABLE"
    
    # Get numeric values for analysis
    RAM_GB=$(free -g | grep Mem | awk '{print $2}')
else
    echo "RAM: Unable to determine (free command not available)"
    RAM_GB=0
fi

# Disk space
if command -v df >/dev/null 2>&1; then
    DISK_INFO=$(df -h / | tail -1)
    echo "Disk Space: $(echo $DISK_INFO | awk '{print $2 " total, " $4 " available, " $5 " used"}')"
    
    # Get numeric values for analysis
    DISK_GB=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
else
    echo "Disk: Unable to determine"
    DISK_GB=0
fi

echo

# Network & Connectivity
echo "--- NETWORK & CONNECTIVITY ---"
echo "External IP: $(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo 'Unable to detect')"

# DNS configuration
if [ -f /etc/resolv.conf ]; then
    echo "DNS Servers:"
    grep nameserver /etc/resolv.conf | head -3 | sed 's/^/  /'
fi

# Test network connectivity
echo "Network Tests:"
if ping -c 1 google.com >/dev/null 2>&1; then
    log_success "Internet connectivity: OK"
else
    log_error "Internet connectivity: FAILED"
fi

if ping -c 1 github.com >/dev/null 2>&1; then
    log_success "GitHub connectivity: OK"
else
    log_error "GitHub connectivity: FAILED"
fi

echo

# Software Versions
echo "--- SOFTWARE VERSIONS ---"

# Docker
if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    echo "Docker: $DOCKER_VERSION"
    
    # Test Docker functionality
    if docker ps >/dev/null 2>&1; then
        log_success "Docker daemon: Running"
        
        # Test Docker with hello-world
        if docker run --rm hello-world >/dev/null 2>&1; then
            log_success "Docker functionality: OK"
        else
            log_warning "Docker functionality: Limited (hello-world failed)"
        fi
    else
        log_error "Docker daemon: Not running or permission denied"
    fi
else
    log_error "Docker: Not installed"
fi

# Docker Compose
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version)
    echo "Docker Compose: $COMPOSE_VERSION"
else
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version)
        echo "Docker Compose (legacy): $COMPOSE_VERSION"
    else
        log_error "Docker Compose: Not installed"
    fi
fi

# Git
if command -v git >/dev/null 2>&1; then
    echo "Git: $(git --version)"
else
    log_error "Git: Not installed"
fi

# Python
if command -v python3 >/dev/null 2>&1; then
    echo "Python: $(python3 --version)"
else
    log_warning "Python3: Not installed"
fi

# Curl/Wget for downloads
if command -v curl >/dev/null 2>&1; then
    echo "Curl: $(curl --version | head -1)"
elif command -v wget >/dev/null 2>&1; then
    echo "Wget: $(wget --version | head -1)"
else
    log_warning "Neither curl nor wget available"
fi

echo

# Security & Access
echo "--- SECURITY & ACCESS ---"

# SSH configuration
if command -v ss >/dev/null 2>&1; then
    SSH_PORT=$(ss -tlnp | grep :22 | head -1 | awk '{print $4}' | cut -d ':' -f 2 2>/dev/null || echo 'Unknown')
    echo "SSH Port: $SSH_PORT"
elif command -v netstat >/dev/null 2>&1; then
    SSH_PORT=$(netstat -tlnp | grep :22 | head -1 | awk '{print $4}' | cut -d ':' -f 2 2>/dev/null || echo 'Unknown')
    echo "SSH Port: $SSH_PORT"
else
    echo "SSH Port: Unable to determine"
fi

# Firewall status
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1 || echo 'Unknown')
    echo "UFW Firewall: $UFW_STATUS"
elif command -v iptables >/dev/null 2>&1; then
    if iptables -L >/dev/null 2>&1; then
        echo "iptables: Available"
    else
        echo "iptables: No permissions"
    fi
else
    echo "Firewall: Not detected"
fi

# SELinux (if applicable)
if command -v sestatus >/dev/null 2>&1; then
    SELINUX_STATUS=$(sestatus 2>/dev/null | grep 'SELinux status' || echo 'SELinux: Disabled/Not present')
    echo "$SELINUX_STATUS"
fi

echo

# Performance baseline
echo "--- PERFORMANCE BASELINE ---"
echo "Load Average: $(uptime | grep -o 'load average:.*' | cut -d ':' -f 2)"

# I/O statistics (if available)
if command -v iostat >/dev/null 2>&1; then
    IO_WAIT=$(iostat 1 2 2>/dev/null | tail -1 | awk '{print $4"%"}' || echo 'N/A')
    echo "I/O Wait: $IO_WAIT"
else
    echo "I/O Wait: iostat not available"
fi

# Memory usage
if command -v free >/dev/null 2>&1; then
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
    echo "Memory Usage: $MEMORY_USAGE"
fi

# Disk usage
if command -v df >/dev/null 2>&1; then
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}')
    echo "Disk Usage: $DISK_USAGE"
fi

echo

# GitHub Actions optimization recommendations
echo "=== GITHUB ACTIONS RECOMMENDATIONS ==="

# RAM-based recommendations
if [ "$RAM_GB" -lt 1 ]; then
    log_warning "LOW RAM ($RAM_GB GB): Use minimal Docker images, enable swap, consider memory-efficient deployment"
    echo "  Recommendations:"
    echo "    - Use alpine-based images"
    echo "    - Enable swap file (fallocate -l 1G /swapfile)"
    echo "    - Use --memory-swap limits in docker-compose"
elif [ "$RAM_GB" -lt 2 ]; then
    log_info "ADEQUATE RAM ($RAM_GB GB): Standard deployment should work"
    echo "  Recommendations:"
    echo "    - Monitor memory usage during deployment"
    echo "    - Use health checks to prevent OOM kills"
else
    log_success "GOOD RAM ($RAM_GB GB): Can run multiple services comfortably"
fi

# Storage recommendations  
if [ "$DISK_GB" -lt 5 ]; then
    log_warning "LOW DISK ($DISK_GB GB): Enable Docker cleanup, use .dockerignore, prune regularly"
    echo "  Recommendations:"
    echo "    - Add 'docker system prune -f' to deployment script"
    echo "    - Use multi-stage builds to reduce image size"
    echo "    - Consider external volume for database"
elif [ "$DISK_GB" -lt 10 ]; then
    log_info "MODERATE DISK ($DISK_GB GB): Good for small deployment, monitor usage"
else
    log_success "SUFFICIENT DISK ($DISK_GB GB): No disk optimizations needed"
fi

# CPU recommendations
if [ "$CPU_CORES" -eq 1 ]; then
    log_warning "SINGLE CORE: Avoid parallel builds, use pre-built images when possible"
    echo "  Recommendations:"
    echo "    - Use 'docker compose pull' instead of building locally"
    echo "    - Set resource limits to prevent CPU starvation"
else
    log_success "MULTI CORE ($CPU_CORES cores): Can handle parallel builds and multiple services"
fi

echo

echo "=== DEPLOYMENT STRATEGY ==="
echo "Recommended approach based on your VPS:"

if [ "$RAM_GB" -ge 2 ] && [ "$CPU_CORES" -ge 2 ] && [ "$DISK_GB" -ge 10 ]; then
    log_success "FULL DEPLOYMENT: Your VPS can handle the complete setup"
    echo "  Strategy:"
    echo "    - Use docker-compose with PostgreSQL + Bot"
    echo "    - Enable health checks and auto-restart"
    echo "    - Use GitHub Actions with caching"
elif [ "$RAM_GB" -ge 1 ] && [ "$DISK_GB" -ge 5 ]; then
    log_info "OPTIMIZED DEPLOYMENT: Use resource-efficient configuration"
    echo "  Strategy:"
    echo "    - Use lightweight PostgreSQL (alpine)"
    echo "    - Set memory limits in docker-compose"
    echo "    - Enable swap if not available"
else
    log_warning "MINIMAL DEPLOYMENT: Consider external database or VPS upgrade"
    echo "  Strategy:"
    echo "    - Consider using external PostgreSQL (e.g., cloud provider)"
    echo "    - Use smallest possible Docker images"
    echo "    - Monitor resource usage closely"
fi

echo
echo "GitHub Actions Configuration:"
echo "  Runner: ubuntu-latest"
echo "  Build method: Docker multi-stage build"
echo "  Deployment: SSH + docker-compose"
echo "  Monitoring: Docker health checks + log aggregation"

echo
echo "=== NEXT STEPS ==="
echo "1. Copy this output and provide it to your deployment setup"
echo "2. Configure GitHub Secrets based on security analysis"
echo "3. Test docker-compose locally before GitHub Actions deployment"
echo "4. Set up log monitoring and alerting"

log_success "VPS Analysis Complete!"
echo "Save this output for your deployment configuration."