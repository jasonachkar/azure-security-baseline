#!/bin/bash
# =============================================================================
# Azure Security Baseline - Sanitization Script
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Azure Security Baseline - Sanitization Check${NC}"
echo "============================================="

# Patterns to search for
GUID_PATTERN='[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
IP_PATTERN='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
EMAIL_PATTERN='[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'

# Known safe patterns (placeholders, examples)
SAFE_GUIDS=(
    "00000000-0000-0000-0000-000000000000"
)

# Files/directories to exclude
EXCLUDE_DIRS=(".git" ".terraform" "node_modules")
EXCLUDE_FILES=("*.tfstate" "*.tfstate.backup")

check_mode=false
redact_mode=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --check    Check for sensitive data (default)"
    echo "  --redact   Attempt to redact sensitive data (use with caution)"
    echo "  --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --check        # Check all files for sensitive data"
    echo "  $0 --redact       # Replace sensitive data with placeholders"
}

# Build find exclude string
build_excludes() {
    excludes=""
    for dir in "${EXCLUDE_DIRS[@]}"; do
        excludes="$excludes -path '*/$dir/*' -prune -o"
    done
    echo "$excludes"
}

check_guids() {
    echo -e "\n${YELLOW}Checking for GUIDs (potential tenant/subscription/object IDs)...${NC}"
    
    found=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            matches=$(grep -oEi "$GUID_PATTERN" "$file" 2>/dev/null | sort -u || true)
            for match in $matches; do
                # Check if it's a known safe placeholder
                is_safe=false
                for safe in "${SAFE_GUIDS[@]}"; do
                    if [[ "${match,,}" == "${safe,,}" ]]; then
                        is_safe=true
                        break
                    fi
                done
                
                if [[ "$is_safe" == false ]]; then
                    echo -e "${RED}Found GUID in $file: $match${NC}"
                    ((found++))
                fi
            done
        fi
    done < <(find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.txt" \) -not -path "*/.git/*" -not -path "*/.terraform/*")
    
    if [[ $found -eq 0 ]]; then
        echo -e "${GREEN}✓ No suspicious GUIDs found${NC}"
    else
        echo -e "${RED}✗ Found $found potential sensitive GUIDs${NC}"
    fi
}

check_ips() {
    echo -e "\n${YELLOW}Checking for IP addresses...${NC}"
    
    found=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            matches=$(grep -oE "$IP_PATTERN" "$file" 2>/dev/null | sort -u || true)
            for match in $matches; do
                # Check if it's a private IP (RFC1918) - these are usually OK for examples
                if [[ "$match" =~ ^10\. ]] || [[ "$match" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ "$match" =~ ^192\.168\. ]]; then
                    continue  # Skip private IPs
                fi
                
                # Skip common safe IPs
                if [[ "$match" == "0.0.0.0" ]] || [[ "$match" == "127.0.0.1" ]]; then
                    continue
                fi
                
                echo -e "${RED}Found public IP in $file: $match${NC}"
                ((found++))
            done
        fi
    done < <(find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.txt" -o -name "*.kql" \) -not -path "*/.git/*" -not -path "*/.terraform/*")
    
    if [[ $found -eq 0 ]]; then
        echo -e "${GREEN}✓ No suspicious public IPs found${NC}"
    else
        echo -e "${RED}✗ Found $found potential sensitive IPs${NC}"
    fi
}

check_emails() {
    echo -e "\n${YELLOW}Checking for email addresses...${NC}"
    
    found=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            matches=$(grep -oEi "$EMAIL_PATTERN" "$file" 2>/dev/null | sort -u || true)
            for match in $matches; do
                # Skip obvious examples
                if [[ "${match,,}" == *"@example.com"* ]] || [[ "${match,,}" == *"@contoso.com"* ]]; then
                    continue
                fi
                
                echo -e "${RED}Found email in $file: $match${NC}"
                ((found++))
            done
        fi
    done < <(find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.txt" \) -not -path "*/.git/*" -not -path "*/.terraform/*")
    
    if [[ $found -eq 0 ]]; then
        echo -e "${GREEN}✓ No suspicious email addresses found${NC}"
    else
        echo -e "${RED}✗ Found $found potential sensitive emails${NC}"
    fi
}

check_secrets() {
    echo -e "\n${YELLOW}Checking for potential secrets...${NC}"
    
    found=0
    patterns=(
        "password"
        "secret"
        "api[_-]?key"
        "access[_-]?key"
        "auth[_-]?token"
        "private[_-]?key"
        "connection[_-]?string"
    )
    
    for pattern in "${patterns[@]}"; do
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                # Skip if it's just a reference (like "password" in documentation)
                if grep -iE "${pattern}\s*[:=]\s*['\"][^'\"]+['\"]" "$file" 2>/dev/null | grep -ivE "(placeholder|example|<|REDACTED)" > /dev/null; then
                    echo -e "${RED}Potential secret ($pattern) in $file${NC}"
                    ((found++))
                fi
            fi
        done < <(find . -type f \( -name "*.json" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env" \) -not -path "*/.git/*" -not -path "*/.terraform/*")
    done
    
    if [[ $found -eq 0 ]]; then
        echo -e "${GREEN}✓ No obvious secrets found${NC}"
    else
        echo -e "${RED}✗ Found $found potential secrets - review manually${NC}"
    fi
}

check_terraform_state() {
    echo -e "\n${YELLOW}Checking for Terraform state files...${NC}"
    
    state_files=$(find . -name "*.tfstate" -o -name "*.tfstate.backup" 2>/dev/null || true)
    
    if [[ -n "$state_files" ]]; then
        echo -e "${RED}✗ Found Terraform state files (should not be committed):${NC}"
        echo "$state_files"
    else
        echo -e "${GREEN}✓ No Terraform state files found${NC}"
    fi
}

check_gitignore() {
    echo -e "\n${YELLOW}Checking .gitignore...${NC}"
    
    if [[ ! -f ".gitignore" ]]; then
        echo -e "${RED}✗ No .gitignore file found${NC}"
        return
    fi
    
    required_entries=(
        "*.tfstate"
        "*.tfvars"
        ".terraform"
        ".env"
    )
    
    for entry in "${required_entries[@]}"; do
        if grep -qF "$entry" .gitignore; then
            echo -e "✓ .gitignore contains: $entry"
        else
            echo -e "${RED}✗ .gitignore missing: $entry${NC}"
        fi
    done
}

generate_report() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Sanitization Check Complete${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo "Recommendations:"
    echo "1. Review any RED items above"
    echo "2. Replace sensitive values with placeholders"
    echo "3. Update SECURITY.md with redaction notes"
    echo "4. Run this check before every commit"
}

# Main
main() {
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        --redact)
            echo -e "${YELLOW}Redact mode not implemented yet. Please manually redact sensitive data.${NC}"
            exit 0
            ;;
        --check|"")
            check_guids
            check_ips
            check_emails
            check_secrets
            check_terraform_state
            check_gitignore
            generate_report
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
