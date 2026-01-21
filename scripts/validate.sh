#!/bin/bash
# =============================================================================
# Azure Security Baseline - Validation Script
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Azure Security Baseline - Validation${NC}"
echo "======================================"

# Get resource names from Terraform output
get_terraform_outputs() {
    cd infra
    export RG_SECURITY=$(terraform output -raw resource_group_names | jq -r '.security')
    export RG_NETWORK=$(terraform output -raw resource_group_names | jq -r '.network')
    export KV_NAME=$(terraform output -raw key_vault | jq -r '.name')
    export LAW_NAME=$(terraform output -raw log_analytics_workspace | jq -r '.name')
    cd ..
}

# Validation functions
validate_key_vault() {
    echo -e "\n${YELLOW}Validating Key Vault...${NC}"
    
    # Check soft delete
    soft_delete=$(az keyvault show --name "$KV_NAME" --query "properties.enableSoftDelete" -o tsv)
    if [[ "$soft_delete" == "true" ]]; then
        echo "✓ Soft delete enabled"
    else
        echo -e "${RED}✗ Soft delete NOT enabled${NC}"
    fi
    
    # Check purge protection
    purge_protection=$(az keyvault show --name "$KV_NAME" --query "properties.enablePurgeProtection" -o tsv)
    if [[ "$purge_protection" == "true" ]]; then
        echo "✓ Purge protection enabled"
    else
        echo -e "${RED}✗ Purge protection NOT enabled${NC}"
    fi
    
    # Check public access
    public_access=$(az keyvault show --name "$KV_NAME" --query "properties.publicNetworkAccess" -o tsv)
    if [[ "$public_access" == "Disabled" ]]; then
        echo "✓ Public network access disabled"
    else
        echo -e "${RED}✗ Public network access NOT disabled${NC}"
    fi
    
    # Check RBAC authorization
    rbac=$(az keyvault show --name "$KV_NAME" --query "properties.enableRbacAuthorization" -o tsv)
    if [[ "$rbac" == "true" ]]; then
        echo "✓ RBAC authorization enabled"
    else
        echo -e "${RED}✗ RBAC authorization NOT enabled${NC}"
    fi
}

validate_nsgs() {
    echo -e "\n${YELLOW}Validating Network Security Groups...${NC}"
    
    # List NSGs and their rules
    nsgs=$(az network nsg list --resource-group "$RG_NETWORK" --query "[].name" -o tsv)
    
    for nsg in $nsgs; do
        echo -e "\nNSG: $nsg"
        
        # Check for explicit deny rule
        deny_rule=$(az network nsg rule list --nsg-name "$nsg" --resource-group "$RG_NETWORK" \
            --query "[?access=='Deny' && direction=='Inbound'].name" -o tsv)
        
        if [[ -n "$deny_rule" ]]; then
            echo "✓ Explicit deny-all-inbound rule found"
        else
            echo -e "${YELLOW}⚠ No explicit deny-all-inbound rule (using implicit deny)${NC}"
        fi
    done
}

validate_private_endpoints() {
    echo -e "\n${YELLOW}Validating Private Endpoints...${NC}"
    
    # List private endpoints
    endpoints=$(az network private-endpoint list --resource-group "$RG_SECURITY" --query "[].{name:name, status:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" -o table)
    
    echo "$endpoints"
    
    # Check Key Vault public access
    kv_public=$(az keyvault show --name "$KV_NAME" --query "properties.publicNetworkAccess" -o tsv)
    if [[ "$kv_public" == "Disabled" ]]; then
        echo "✓ Key Vault public access disabled"
    else
        echo -e "${RED}✗ Key Vault still has public access${NC}"
    fi
}

validate_diagnostic_settings() {
    echo -e "\n${YELLOW}Validating Diagnostic Settings...${NC}"
    
    # Check Key Vault diagnostic settings
    kv_diag=$(az monitor diagnostic-settings list --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_SECURITY/providers/Microsoft.KeyVault/vaults/$KV_NAME" --query "[].name" -o tsv)
    
    if [[ -n "$kv_diag" ]]; then
        echo "✓ Key Vault diagnostic settings configured"
    else
        echo -e "${RED}✗ Key Vault diagnostic settings NOT configured${NC}"
    fi
}

validate_log_analytics() {
    echo -e "\n${YELLOW}Validating Log Analytics Workspace...${NC}"
    
    # Check retention
    retention=$(az monitor log-analytics workspace show --workspace-name "$LAW_NAME" --resource-group "$RG_SECURITY" --query "retentionInDays" -o tsv)
    echo "Log retention: $retention days"
    
    if [[ "$retention" -ge 90 ]]; then
        echo "✓ Retention >= 90 days"
    else
        echo -e "${YELLOW}⚠ Retention < 90 days (may not meet compliance requirements)${NC}"
    fi
}

generate_report() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Validation Complete${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review any failures above"
    echo "2. Capture screenshots for evidence/"
    echo "3. Update controls-matrix.md with results"
}

# Main
main() {
    echo "Loading Terraform outputs..."
    # Uncomment when Terraform is applied:
    # get_terraform_outputs
    
    # For now, prompt for values
    echo -e "${YELLOW}Enter resource group name (security):${NC}"
    read -r RG_SECURITY
    echo -e "${YELLOW}Enter resource group name (network):${NC}"
    read -r RG_NETWORK
    echo -e "${YELLOW}Enter Key Vault name:${NC}"
    read -r KV_NAME
    echo -e "${YELLOW}Enter Log Analytics workspace name:${NC}"
    read -r LAW_NAME
    
    validate_key_vault
    validate_nsgs
    validate_private_endpoints
    validate_diagnostic_settings
    validate_log_analytics
    generate_report
}

main "$@"
