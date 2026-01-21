# Secrets Management

This section documents the secrets management controls implemented in this security baseline.

## Overview

Secrets management ensures credentials, keys, and certificates are stored securely and accessed without exposing them in code or configuration:

1. **Azure Key Vault** — Centralized secrets storage
2. **Managed Identity** — Passwordless authentication to Azure services
3. **No Secrets in Code** — Environment isolation and secret injection
4. **Rotation Policies** — Automated key/secret rotation

## Controls Implemented

### Key Vault Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| SKU | Standard (or Premium for HSM) | Cost-effective for most scenarios |
| Soft Delete | Enabled (90 days) | Recovery from accidental deletion |
| Purge Protection | Enabled | Prevent permanent deletion |
| Public Network Access | Disabled | Private endpoint only |
| RBAC Authorization | Enabled | RBAC over access policies |

See [keyvault-setup.md](keyvault-setup.md) for full configuration.

### Managed Identity Usage

| Resource | Identity Type | Key Vault Role | Secrets Accessed |
|----------|--------------|----------------|------------------|
| App Service | System-assigned | Key Vault Secrets User | Database connection string |
| Function App | System-assigned | Key Vault Secrets User | API keys |
| AKS | User-assigned | Key Vault Secrets User | Application secrets |

See [managed-identity-pattern.md](managed-identity-pattern.md) for implementation patterns.

### Secret Types & Rotation

| Secret Type | Storage | Rotation Period | Rotation Method |
|-------------|---------|-----------------|-----------------|
| Database connection strings | Key Vault | 90 days | Manual + alert |
| API keys (internal) | Key Vault | 90 days | Automated rotation |
| API keys (external) | Key Vault | Per vendor | Manual |
| TLS certificates | Key Vault | Auto-renew | App Service integration |

## Validation Tests

### Test 1: No Secrets in Code

**Objective:** Verify application retrieves secrets from Key Vault, not environment/code

**Steps:**
1. Review application configuration
2. Verify Key Vault references (not plaintext secrets)
3. Check deployment scripts for secret handling
4. Scan repository with secret detection tool

**Evidence:** [View screenshot](evidence/test-no-secrets-in-code.png)

### Test 2: Managed Identity Access

**Objective:** Verify managed identity can retrieve secrets

**Steps:**
1. From application, request secret from Key Vault
2. Expected: Secret retrieved successfully
3. Check Key Vault audit logs for access event
4. Verify no credentials in request (managed identity token)

**Evidence:** [View screenshot](evidence/test-managed-identity.png)

### Test 3: Unauthorized Access Blocked

**Objective:** Verify unauthorized principals cannot access secrets

**Steps:**
1. From unauthorized identity, attempt to read secret
2. Expected: 403 Forbidden
3. Check Key Vault audit logs for denied event

**Evidence:** [View screenshot](evidence/test-unauthorized-blocked.png)

### Test 4: Secret Rotation

**Objective:** Verify secret rotation process works

**Steps:**
1. Trigger secret rotation (manual or automated)
2. Verify new secret version created
3. Verify application picks up new secret
4. Verify old secret version still accessible (grace period)

**Evidence:** [View screenshot](evidence/test-secret-rotation.png)

## Code Patterns

### Retrieving Secrets in .NET

```csharp
// Using Azure.Identity with managed identity
var client = new SecretClient(
    new Uri("https://<keyvault-name>.vault.azure.net/"),
    new DefaultAzureCredential()
);

KeyVaultSecret secret = await client.GetSecretAsync("DatabaseConnectionString");
string connectionString = secret.Value;
```

### Key Vault Reference in App Service

```json
// In app settings - reference, not value
{
  "ConnectionStrings__Default": "@Microsoft.KeyVault(VaultName=kv-workload;SecretName=DatabaseConnectionString)"
}
```

### Terraform Key Vault Secret Access

```hcl
# Grant managed identity access to secrets
resource "azurerm_role_assignment" "app_keyvault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}
```

## Monitoring & Detection

### KQL Queries for Key Vault Monitoring

```kql
// All secret access in last 24 hours
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where ResourceType == "VAULTS"
| where OperationName == "SecretGet"
| project TimeGenerated, CallerIPAddress, identity_claim_upn_s, ResultType

// Failed access attempts
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where ResourceType == "VAULTS"
| where ResultType != "Success"
| project TimeGenerated, OperationName, CallerIPAddress, ResultType, ResultDescription

// Secret modifications
AzureDiagnostics
| where TimeGenerated > ago(7d)
| where ResourceType == "VAULTS"
| where OperationName in ("SecretSet", "SecretDelete", "SecretRecover", "SecretPurge")
| project TimeGenerated, OperationName, identity_claim_upn_s
```

## Related Documentation

- [Key Vault Setup](keyvault-setup.md)
- [Managed Identity Pattern](managed-identity-pattern.md)
- [Controls Matrix](../docs/controls-matrix.md)
- [Threat Model - Key Vault Section](../docs/threat-model.md#component-key-vault)

## Implementation Checklist

- [ ] Key Vault: Created with soft delete and purge protection
- [ ] Key Vault: Public access disabled, private endpoint configured
- [ ] Key Vault: RBAC authorization enabled
- [ ] Managed Identity: Configured for all applications
- [ ] Managed Identity: Granted minimum necessary roles
- [ ] Secrets: Migrated from code/config to Key Vault
- [ ] Secrets: Rotation policy documented
- [ ] Monitoring: Audit logging enabled
- [ ] Monitoring: Alert on failed access attempts
- [ ] Evidence: Screenshots captured for all controls
- [ ] Validation: All test cases executed and documented
