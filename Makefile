.PHONY: help init plan apply destroy validate fmt clean setup

.DEFAULT_GOAL := help

help: ## Show available commands
	@echo "ProxFleet - Terraform Proxmox VM Management"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

setup: ## Copy example configs to config/
	@if [ ! -f config/.env ]; then \
		cp docs/examples/.env.example config/.env; \
		echo "Created config/.env - edit with your credentials"; \
	fi
	@if [ ! -f config/infrastructure.tfvars ]; then \
		cp docs/examples/infrastructure.tfvars.example config/infrastructure.tfvars; \
	fi
	@if [ ! -f config/vms.tfvars ]; then \
		cp docs/examples/vms.tfvars.example config/vms.tfvars; \
	fi
	@echo "Setup complete! Edit config/.env with your Proxmox credentials"

##@ Terraform

init: ## Initialize Teraform
	@terraform init

plan: ## Preview changes
	@terraform plan -var-file=config/infrastructure.tfvars -var-file=config/vms.tfvars

apply: ## Apply changes
	@terraform apply -var-file=config/infrastructure.tfvars -var-file=config/vms.tfvars

destroy: ## Destroy all VMs
	@terraform destroy -var-file=config/infrastructure.tfvars -var-file=config/vms.tfvars

output: ## Show outputs
	@terraform output

##@ Validation

validate: ## Validate Terraform files
	@terraform fmt -check -recursive
	@terraform validate

fmt: ## Format Terraform files
	@terraform fmt -recursive

##@ Cleanup

clean: ## Remove Terraform cache
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@rm -f *.tfstate.backup
