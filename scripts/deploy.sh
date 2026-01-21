#!/bin/bash
# =============================================================================
# Azure Security Baseline - Deployment Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Azure Security Baseline - Deployment${NC}"
echo "======================================"

# Check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}Checking prerequisites...${NC}"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli${NC}"
        exit 1
    fi
    echo "✓ Azure CLI found"

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform not found. Please install: https://learn.hashicorp.com/tutorials/terraform/install-cli${NC}"
        exit 1
    fi
    echo "✓ Terraform found"

    # Check Azure login
    if ! az account show &> /dev/null; then
        echo -e "${YELLOW}Not logged in to Azure. Running 'az login'...${NC}"
        az login
    fi
    echo "✓ Azure CLI authenticated"
}

# Display current context
show_context() {
    echo -e "\n${YELLOW}Current Azure Context:${NC}"
    az account show --query "{Name:name, ID:id, TenantId:tenantId}" -o table
    
    echo -e "\n${YELLOW}Continue with this subscription? (y/n)${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted. Use 'az account set --subscription <id>' to change subscription."
        exit 1
    fi
}

# Initialize Terraform
init_terraform() {
    echo -e "\n${YELLOW}Initializing Terraform...${NC}"
    cd infra
    terraform init
    echo "✓ Terraform initialized"
}

# Plan deployment
plan_deployment() {
    echo -e "\n${YELLOW}Planning deployment...${NC}"
    
    # Check for tfvars file
    if [[ ! -f "terraform.tfvars" ]]; then
        echo -e "${YELLOW}No terraform.tfvars found. Using defaults.${NC}"
        echo "Create terraform.tfvars to customize deployment."
    fi
    
    terraform plan -out=tfplan
    echo "✓ Plan saved to tfplan"
}

# Apply deployment
apply_deployment() {
    echo -e "\n${YELLOW}Apply this plan? (y/n)${NC}"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        echo -e "\n${GREEN}✓ Deployment complete!${NC}"
    else
        echo "Deployment cancelled."
    fi
}

# Main
main() {
    check_prerequisites
    show_context
    init_terraform
    plan_deployment
    apply_deployment
    
    echo -e "\n${GREEN}Next steps:${NC}"
    echo "1. Run ./scripts/validate.sh to verify deployment"
    echo "2. Capture evidence screenshots"
    echo "3. Update documentation with actual values"
}

main "$@"
