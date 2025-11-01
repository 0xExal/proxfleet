#!/bin/bash
# ProxFleet - Configuration Validator
# Validates configuration files before applying

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Change to script directory's parent
cd "$(dirname "$0")/.."

print_header "ProxFleet Configuration Validator"

# Check if required files exist
print_header "Checking Required Files"

if [ -f "config/.env" ]; then
    print_success "config/.env exists"
else
    print_error "config/.env not found"
fi

if [ -f "config/infrastructure.tfvars" ]; then
    print_success "config/infrastructure.tfvars exists"
else
    print_error "config/infrastructure.tfvars not found"
fi

if [ -f "config/vms.tfvars" ]; then
    print_success "config/vms.tfvars exists"
else
    print_error "config/vms.tfvars not found"
fi

# Check .env file for placeholder values
print_header "Checking .env Configuration"

if [ -f "config/.env" ]; then
    if grep -q "your-proxmox.local" config/.env 2>/dev/null; then
        print_warning ".env contains placeholder values (your-proxmox.local)"
    fi

    if grep -q "your-secure-password" config/.env 2>/dev/null; then
        print_error ".env contains placeholder password"
    fi

    if grep -q "user@host" config/.env 2>/dev/null; then
        print_warning ".env contains placeholder SSH key"
    fi

    # Check for required variables
    if grep -q "^PROXMOX_ENDPOINT=" config/.env; then
        print_success "PROXMOX_ENDPOINT defined"
    else
        print_error "PROXMOX_ENDPOINT not defined in .env"
    fi

    if grep -q "^PROXMOX_USERNAME=" config/.env; then
        print_success "PROXMOX_USERNAME defined"
    else
        print_error "PROXMOX_USERNAME not defined in .env"
    fi

    if grep -q "^SSH_PUBLIC_KEY=" config/.env; then
        print_success "SSH_PUBLIC_KEY defined"
    else
        print_error "SSH_PUBLIC_KEY not defined in .env"
    fi
fi

# Check infrastructure.tfvars for placeholder values
print_header "Checking Infrastructure Configuration"

if [ -f "config/infrastructure.tfvars" ]; then
    if grep -q "your-proxmox.local" config/infrastructure.tfvars 2>/dev/null; then
        print_warning "infrastructure.tfvars contains placeholder endpoint"
    fi

    # Check template_vm_id
    if grep -q "^template_vm_id" config/infrastructure.tfvars; then
        TEMPLATE_ID=$(grep "^template_vm_id" config/infrastructure.tfvars | sed 's/.*=\s*//' | tr -d ' ')
        if [ "$TEMPLATE_ID" = "9000" ]; then
            print_success "template_vm_id defined (${TEMPLATE_ID})"
        else
            print_success "template_vm_id defined (${TEMPLATE_ID})"
        fi
    else
        print_error "template_vm_id not defined"
    fi
fi

# Check VMs configuration
print_header "Checking VMs Configuration"

if [ -f "config/vms.tfvars" ]; then
    # Count VMs
    VM_COUNT=$(grep -c "vm_id\s*=" config/vms.tfvars 2>/dev/null || echo "0")
    if [ "$VM_COUNT" -gt 0 ]; then
        print_success "Found $VM_COUNT VM(s) defined"
    else
        print_warning "No VMs defined in vms.tfvars"
    fi

    # Check for duplicate VM IDs
    DUPLICATE_IDS=$(grep "vm_id\s*=" config/vms.tfvars | sed 's/.*=\s*//' | tr -d ' ' | sort | uniq -d)
    if [ -n "$DUPLICATE_IDS" ]; then
        print_error "Duplicate VM IDs found: $DUPLICATE_IDS"
    else
        print_success "No duplicate VM IDs"
    fi
fi

# Check Terraform installation
print_header "Checking Dependencies"

if command -v terraform >/dev/null 2>&1; then
    TF_VERSION=$(terraform version | head -n1 | cut -d'v' -f2)
    print_success "Terraform installed (${TF_VERSION})"

    # Check minimum version
    MIN_VERSION="1.5.0"
    if [ "$(printf '%s\n' "$MIN_VERSION" "$TF_VERSION" | sort -V | head -n1)" = "$MIN_VERSION" ]; then
        print_success "Terraform version >= ${MIN_VERSION}"
    else
        print_error "Terraform version < ${MIN_VERSION} (found ${TF_VERSION})"
    fi
else
    print_error "Terraform not installed"
fi

if command -v ssh >/dev/null 2>&1; then
    print_success "SSH available"
else
    print_error "SSH not available"
fi

# Run Terraform validate if possible
if [ -d ".terraform" ]; then
    print_header "Running Terraform Validate"
    if terraform validate >/dev/null 2>&1; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform validation failed"
        terraform validate
    fi
else
    print_warning "Terraform not initialized (.terraform directory not found)"
    echo "  Run: terraform init"
fi

# Summary
print_header "Validation Summary"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "Your configuration is ready to use."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo "Configuration may work but review warnings above."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo "Please fix the errors before proceeding."
    exit 1
fi
