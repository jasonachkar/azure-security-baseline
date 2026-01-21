# Security & Sanitization Guide

This document explains how sensitive information is handled in this repository and how to adapt templates for your environment.

## What Has Been Redacted

All configurations use placeholder values for sensitive identifiers:

| Sensitive Data | Placeholder Used | Example |
|---------------|------------------|---------|
| Tenant ID | `<TENANT_ID>` or `00000000-0000-0000-0000-000000000000` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Subscription ID | `<SUBSCRIPTION_ID>` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Object IDs (users/groups/SPs) | `<OBJECT_ID>` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Resource IDs | Generic paths | `/subscriptions/<SUBSCRIPTION_ID>/...` |
| IP addresses | `10.x.x.x` or `<YOUR_IP>` | Internal RFC1918 ranges only |
| Domain names | `contoso.com` or `<YOUR_DOMAIN>` | — |
| Key Vault secrets | Never committed | — |
| Connection strings | Never committed | — |

## Before Committing: Sanitization Checklist

Run this checklist before every commit:

- [ ] **No real tenant IDs** — Search for GUIDs, replace with placeholders
- [ ] **No real subscription IDs** — Check Terraform state, outputs, evidence screenshots
- [ ] **No real object IDs** — User GUIDs, service principal IDs, group IDs
- [ ] **No real IP addresses** — Except RFC1918 private ranges for examples
- [ ] **No secrets/keys** — No connection strings, SAS tokens, passwords, API keys
- [ ] **Screenshots redacted** — Blur or box out sensitive values in evidence images
- [ ] **Terraform state excluded** — `.tfstate` files in `.gitignore`
- [ ] **No `.env` files** — Environment files excluded

### Automated Check

```bash
# Run the sanitization check script
./scripts/sanitize.sh --check

# Auto-redact common patterns (review output carefully)
./scripts/sanitize.sh --redact
```

## Adapting Templates for Your Environment

### Step 1: Create a `terraform.tfvars` file (do NOT commit)

```hcl
# terraform.tfvars - ADD TO .gitignore
tenant_id       = "your-actual-tenant-id"
subscription_id = "your-actual-subscription-id"
location        = "canadacentral"
environment     = "dev"
```

### Step 2: Use variables, never hardcode

```hcl
# Good - uses variable
resource "azurerm_resource_group" "main" {
  name     = "rg-security-${var.environment}"
  location = var.location
}

# Bad - hardcoded
resource "azurerm_resource_group" "main" {
  name     = "rg-security-prod"
  location = "eastus"
}
```

### Step 3: For evidence screenshots

1. Take screenshot
2. Open in image editor
3. Redact: tenant ID, subscription ID, object IDs, email addresses, IP addresses
4. Save to `/evidence/` folder with descriptive name

## Sensitive Patterns to Watch For

### In Azure Portal Screenshots
- Top URL bar (contains subscription ID)
- Resource ID fields
- User/group object IDs in IAM blade
- Email addresses in audit logs
- IP addresses in NSG/firewall logs

### In Terraform/JSON
```
# These patterns should trigger a review:
"tenantId": "????????-????-????-????-????????????"
"subscriptionId": "????????-????-????-????-????????????"
"objectId": "????????-????-????-????-????????????"
"principalId": "????????-????-????-????-????????????"
```

### In KQL Queries
```kql
// Watch for hardcoded IPs or user identities
| where IPAddress == "203.0.113.50"        // Redact real IPs
| where UserPrincipalName == "user@domain" // Redact real UPNs
```

## Reporting Security Issues

If you discover sensitive data that was accidentally committed:

1. **Do not open a public issue**
2. Contact: [your-email] or open a private security advisory
3. The exposed credentials will be rotated immediately

## Files Excluded from Repository

See `.gitignore`:

```
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
.terraform/

# Secrets
.env
*.pem
*.key
secrets/

# Local overrides
local.tf
override.tf
```
