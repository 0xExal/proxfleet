#!/bin/bash
# ProxFleet - Template VM Setup Script
# This script helps prepare a Proxmox VM template for use with ProxFleet

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

print_header "ProxFleet Template VM Setup"

echo "This script will:"
echo "  1. Install cloud-init"
echo "  2. Install and enable QEMU Guest Agent"
echo "  3. Clean cloud-init data"
echo "  4. Reset machine-id"
echo "  5. Prepare the VM to be converted to a template"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Aborted by user"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    print_error "Cannot detect OS"
    exit 1
fi

print_header "Installing Required Packages"

case $OS in
    ubuntu|debian)
        print_success "Detected: $PRETTY_NAME"
        apt-get update
        apt-get install -y cloud-init qemu-guest-agent
        ;;
    *)
        print_error "Unsupported OS: $OS"
        exit 1
        ;;
esac

print_success "Packages installed"

print_header "Enabling QEMU Guest Agent"
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent
print_success "QEMU Guest Agent enabled and started"

print_header "Configuring Cloud-Init"

# Configure cloud-init datasource
cat > /etc/cloud/cloud.cfg.d/99_proxmox.cfg << 'EOF'
# Cloud-init configuration for Proxmox
datasource_list: [ NoCloud, ConfigDrive ]

# Disable network config from cloud-init
network:
  config: disabled
EOF

print_success "Cloud-init configured for Proxmox"

print_header "Cleaning Up for Template"

# Stop services
systemctl stop qemu-guest-agent || true

# Clean cloud-init
cloud-init clean --logs --seed
rm -rf /var/lib/cloud/instances
rm -rf /var/lib/cloud/instance

# Clean machine-id (will be regenerated on first boot)
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Clean shell history
history -c
rm -f ~/.bash_history
rm -f /root/.bash_history

# Clean temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clean log files
find /var/log -type f -exec truncate -s 0 {} \;

# Clean SSH host keys (will be regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

print_success "VM cleaned and ready for template conversion"

print_header "Template Preparation Complete"

echo -e "${GREEN}The VM is now ready to be converted to a template!${NC}"
echo ""
echo "Next steps:"
echo "  1. Shutdown this VM: ${YELLOW}shutdown -h now${NC}"
echo "  2. On Proxmox host, convert to template:"
echo "     ${YELLOW}qm template <VMID>${NC}"
echo "  3. Update ProxFleet config with the template ID"
echo ""
print_warning "After shutdown, do NOT start this VM again before converting to template!"
