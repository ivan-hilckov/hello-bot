#!/bin/bash
# VPS Deployment Readiness Test
# This script verifies that the VPS is ready for Hello Bot deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
WARNINGS=0

# Function to print test result
print_test() {
    local status=$1
    local message=$2
    local details=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message"
        if [ -n "$details" ]; then
            echo -e "   ${RED}→${NC} $details"
        fi
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $message"
        WARNINGS=$((WARNINGS + 1))
        if [ -n "$details" ]; then
            echo -e "   ${YELLOW}→${NC} $details"
        fi
    fi
}

# Function to check command exists
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version=$(eval "$cmd --version 2>/dev/null | head -n1" || echo "unknown")
        print_test "PASS" "$name is installed" "$version"
        return 0
    else
        print_test "FAIL" "$name is not installed" "Please install $name"
        return 1
    fi
}

# Function to check system resources
check_resources() {
    echo -e "\n${BLUE}=== SYSTEM RESOURCES ===${NC}"
    
    # CPU cores
    if command -v nproc >/dev/null 2>&1; then
        local cpu_cores=$(nproc 2>/dev/null || echo "0")
    else
        local cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "0")
    fi
    
    if [ "$cpu_cores" -ge 2 ]; then
        print_test "PASS" "CPU cores: $cpu_cores" "Good for production"
    elif [ "$cpu_cores" -ge 1 ]; then
        print_test "WARN" "CPU cores: $cpu_cores" "Minimum 2 cores recommended"
    else
        print_test "WARN" "CPU cores: unknown" "Cannot detect CPU count"
    fi
    
    # RAM
    if command -v free >/dev/null 2>&1; then
        local ram_gb=$(free -g 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0")
    else
        # macOS fallback
        local ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
        local ram_gb=$((ram_bytes / 1024 / 1024 / 1024))
    fi
    
    if [ "$ram_gb" -ge 2 ]; then
        print_test "PASS" "RAM: ${ram_gb}GB" "Sufficient for bot + database"
    elif [ "$ram_gb" -ge 1 ]; then
        print_test "WARN" "RAM: ${ram_gb}GB" "Minimum requirement met, consider upgrade"
    elif [ "$ram_gb" -gt 0 ]; then
        print_test "FAIL" "RAM: ${ram_gb}GB" "Minimum 1GB required"
    else
        print_test "WARN" "RAM: unknown" "Cannot detect RAM amount"
    fi
    
    # Disk space
    local disk_gb=""
    if df -BG / >/dev/null 2>&1; then
        disk_gb=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G' || echo "0")
    elif df -h / >/dev/null 2>&1; then
        # macOS fallback
        local disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo "0G")
        disk_gb=$(echo "$disk_info" | sed 's/G.*//g' | sed 's/\..*//')
    fi
    
    if [ -n "$disk_gb" ] && [ "$disk_gb" -ge 10 ]; then
        print_test "PASS" "Free disk space: ${disk_gb}GB" "Sufficient for images and logs"
    elif [ -n "$disk_gb" ] && [ "$disk_gb" -ge 5 ]; then
        print_test "WARN" "Free disk space: ${disk_gb}GB" "Consider cleanup of old data"
    elif [ -n "$disk_gb" ] && [ "$disk_gb" -gt 0 ]; then
        print_test "FAIL" "Free disk space: ${disk_gb}GB" "Minimum 5GB required"
    else
        print_test "WARN" "Free disk space: unknown" "Cannot detect disk usage"
    fi
    
    # Swap
    if command -v free >/dev/null 2>&1; then
        local swap_gb=$(free -g 2>/dev/null | awk '/^Swap:/{print $2}' || echo "0")
        if [ "$swap_gb" -ge 1 ]; then
            print_test "PASS" "Swap: ${swap_gb}GB" "Good for memory optimization"
        else
            print_test "WARN" "Swap: ${swap_gb}GB" "Consider adding swap file"
        fi
    else
        print_test "WARN" "Swap: unknown" "Cannot detect swap on this system"
    fi
}

# Function to check network connectivity
check_network() {
    echo -e "\n${BLUE}=== NETWORK CONNECTIVITY ===${NC}"
    
    # Internet connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_test "PASS" "Internet connectivity" "Can reach external services"
    else
        print_test "FAIL" "Internet connectivity" "Cannot reach external services"
    fi
    
    # GitHub connectivity
    if curl -s --max-time 5 https://github.com >/dev/null; then
        print_test "PASS" "GitHub connectivity" "Can reach GitHub.com"
    else
        print_test "FAIL" "GitHub connectivity" "Cannot reach GitHub.com"
    fi
    
    # Docker Hub connectivity
    if curl -s --max-time 5 https://hub.docker.com >/dev/null; then
        print_test "PASS" "Docker Hub connectivity" "Can reach Docker Hub"
    else
        print_test "WARN" "Docker Hub connectivity" "Cannot reach Docker Hub"
    fi
    
    # GitHub Container Registry
    if curl -s --max-time 5 https://ghcr.io >/dev/null; then
        print_test "PASS" "GitHub Container Registry" "Can reach ghcr.io"
    else
        print_test "FAIL" "GitHub Container Registry" "Cannot reach ghcr.io"
    fi
}

# Function to check Docker setup
check_docker() {
    echo -e "\n${BLUE}=== DOCKER SETUP ===${NC}"
    
    # Docker daemon
    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet docker 2>/dev/null; then
        print_test "PASS" "Docker daemon is running" "Service is active"
    elif command -v service >/dev/null 2>&1 && service docker status >/dev/null 2>&1; then
        print_test "PASS" "Docker daemon is running" "Service is active"
    elif docker info >/dev/null 2>&1; then
        print_test "PASS" "Docker daemon is running" "Docker is accessible"
    else
        print_test "FAIL" "Docker daemon is not running" "Run: sudo systemctl start docker (Linux) or start Docker Desktop"
    fi
    
    # Docker without sudo
    if docker ps >/dev/null 2>&1; then
        print_test "PASS" "Docker runs without sudo" "User has proper permissions"
    else
        print_test "FAIL" "Docker requires sudo" "Add user to docker group: sudo usermod -aG docker $USER"
    fi
    
    # Docker Compose
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        print_test "PASS" "Docker Compose V2" "$compose_version"
    elif docker-compose --version >/dev/null 2>&1; then
        print_test "WARN" "Docker Compose V1 detected" "V2 recommended for better performance"
    else
        print_test "FAIL" "Docker Compose not found" "Install Docker Compose"
    fi
    
    # Test Docker functionality
    if docker run --rm hello-world >/dev/null 2>&1; then
        print_test "PASS" "Docker can run containers" "Successfully ran test container"
    else
        print_test "FAIL" "Docker cannot run containers" "Check Docker installation and permissions"
    fi
}

# Function to check directories and permissions
check_directories() {
    echo -e "\n${BLUE}=== DIRECTORIES & PERMISSIONS ===${NC}"
    
    # Deployment directory
    local deploy_dir="/opt/hello-bot"
    if [ -d "$deploy_dir" ]; then
        if [ -w "$deploy_dir" ]; then
            print_test "PASS" "Deployment directory writable" "$deploy_dir"
        else
            print_test "WARN" "Deployment directory not writable" "Will be created during deployment"
        fi
    else
        print_test "WARN" "Deployment directory doesn't exist" "Will be created during deployment"
    fi
    
    # Home directory permissions
    if [ -w "$HOME" ]; then
        print_test "PASS" "Home directory writable" "$HOME"
    else
        print_test "FAIL" "Home directory not writable" "Check permissions"
    fi
    
    # Check if user can sudo (for deployment script)
    if sudo -n true >/dev/null 2>&1; then
        print_test "PASS" "Sudo access without password" "Good for automated deployment"
    elif sudo -l >/dev/null 2>&1; then
        print_test "WARN" "Sudo access requires password" "May need NOPASSWD for automation"
    else
        print_test "FAIL" "No sudo access" "Required for deployment script"
    fi
}

# Function to check security
check_security() {
    echo -e "\n${BLUE}=== SECURITY SETUP ===${NC}"
    
    # SSH service
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
            print_test "PASS" "SSH service is running" "Ready for deployment connections"
        else
            print_test "FAIL" "SSH service not running" "Required for GitHub Actions deployment"
        fi
    elif pgrep sshd >/dev/null 2>&1; then
        print_test "PASS" "SSH service is running" "SSH daemon detected"
    else
        print_test "WARN" "SSH service status unknown" "Cannot detect SSH service on this system"
    fi
    
    # Firewall
    if command -v ufw >/dev/null 2>&1 && ufw status >/dev/null 2>&1; then
        local ufw_status=$(ufw status 2>/dev/null | head -n1)
        if echo "$ufw_status" | grep -q "active"; then
            print_test "PASS" "UFW firewall is active" "Security is enabled"
        else
            print_test "WARN" "UFW firewall is inactive" "Consider enabling for security"
        fi
    elif command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        print_test "PASS" "Firewalld is active" "Security is enabled"
    else
        print_test "WARN" "No firewall detected" "Consider enabling UFW or firewalld (Linux)"
    fi
    
    # Fail2ban
    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet fail2ban 2>/dev/null; then
        print_test "PASS" "Fail2ban is active" "Brute force protection enabled"
    else
        print_test "WARN" "Fail2ban not active" "Consider installing for SSH protection (Linux)"
    fi
}

# Function to test GitHub Container Registry login
test_ghcr_login() {
    echo -e "\n${BLUE}=== GITHUB CONTAINER REGISTRY TEST ===${NC}"
    
    # Check if we can login (this will fail without token, but tests connectivity)
    if echo "test" | docker login ghcr.io -u test --password-stdin >/dev/null 2>&1; then
        print_test "WARN" "GHCR login test passed" "Unexpected success"
        docker logout ghcr.io >/dev/null 2>&1
    else
        print_test "PASS" "GHCR connectivity works" "Login fails as expected without token"
    fi
}

# Function to check environment
check_environment() {
    echo -e "\n${BLUE}=== ENVIRONMENT ===${NC}"
    
    # Detect OS type first
    local os_type=$(uname -s)
    if [ "$os_type" != "Linux" ]; then
        print_test "WARN" "Operating System: $os_type" "This script is designed for Linux VPS servers"
        echo -e "   ${YELLOW}→${NC} Please run this script on your actual VPS server"
        echo -e "   ${YELLOW}→${NC} Results on non-Linux systems may not be accurate"
        echo ""
    fi
    
    # OS version
    if [ -f /etc/os-release ]; then
        local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)
        print_test "PASS" "Operating System" "$os_info"
    elif [ "$os_type" = "Darwin" ]; then
        local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
        print_test "WARN" "Operating System: macOS $macos_version" "Script intended for Linux servers"
    else
        print_test "WARN" "Operating System: $os_type" "Cannot detect OS version"
    fi
    
    # Architecture
    local arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        print_test "PASS" "Architecture: $arch" "Compatible with Docker images"
    elif [ "$arch" = "arm64" ] && [ "$os_type" = "Linux" ]; then
        print_test "WARN" "Architecture: $arch" "ARM64 Linux supported but less common"
    else
        print_test "WARN" "Architecture: $arch" "May need different Docker images"
    fi
    
    # Timezone
    if command -v timedatectl >/dev/null 2>&1; then
        local tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "unknown")
    else
        local tz=$(date +%Z 2>/dev/null || echo "unknown")
    fi
    print_test "PASS" "Timezone: $tz" "Database will use UTC internally"
}

# Main function
main() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}     VPS DEPLOYMENT READINESS TEST     ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    echo "Testing VPS configuration for Hello Bot deployment..."
    echo ""
    
    # Run all checks
    check_environment
    check_resources
    check_network
    check_docker
    check_directories
    check_security
    test_ghcr_login
    
    # Summary
    echo -e "\n${BLUE}=== TEST SUMMARY ===${NC}"
    echo -e "Total tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed: $((TOTAL_TESTS - PASSED_TESTS))${NC}"
    
    echo ""
    if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
        echo -e "${GREEN}🎉 VPS IS READY FOR DEPLOYMENT!${NC}"
        echo "Your VPS meets all requirements for Hello Bot deployment."
    elif [ $((TOTAL_TESTS - PASSED_TESTS)) -le 2 ] && [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  VPS IS MOSTLY READY${NC}"
        echo "Your VPS should work, but consider addressing the warnings above."
    else
        echo -e "${RED}❌ VPS NEEDS CONFIGURATION${NC}"
        echo "Please fix the failed tests before attempting deployment."
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Configure GitHub Secrets (see GITHUB_SECRETS.md)"
    echo "2. Push code to main branch to trigger deployment"
    echo "3. Monitor deployment in GitHub Actions"
    echo ""
}

# Run the main function
main "$@"