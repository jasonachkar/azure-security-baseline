# Identity & Access Management

This section documents the identity and access controls implemented in this security baseline.

## Overview

Identity is the primary security perimeter in cloud environments. This baseline implements defense-in-depth for identity through:

1. **Conditional Access** — Policy-based access control
2. **RBAC** — Least privilege role assignments
3. **PIM** — Just-in-time privileged access
4. **Entra ID Protection** — Risk-based policies

## Controls Implemented

### Conditional Access Policies

| Policy Name | Target | Conditions | Controls | Evidence |
|-------------|--------|------------|----------|----------|
| Require MFA for all users | All users | All cloud apps | MFA required | [View](evidence/CA-require-mfa.png) |
| Block legacy authentication | All users | All cloud apps, legacy clients | Block | [View](evidence/CA-block-legacy.png) |
| Require compliant device for admins | Admin roles | All cloud apps | Compliant device + MFA | [View](evidence/CA-admin-device.png) |
| Risk-based sign-in policy | All users | High sign-in risk | MFA + password change | [View](evidence/CA-risk-signin.png) |

See [conditional-access-policies.md](conditional-access-policies.md) for full policy details.

### RBAC Assignments

| Role | Scope | Principal Type | Justification |
|------|-------|----------------|---------------|
| Reader | Subscription | Security group | Default access for all users |
| Contributor | Resource Group (workload) | Managed Identity | App deployment |
| Key Vault Secrets User | Key Vault | Managed Identity | Secret retrieval only |
| Security Reader | Subscription | Security team group | Security monitoring |

See [rbac-assignments.md](rbac-assignments.md) for detailed assignments.

**Principles applied:**
- No standing Owner/Contributor at subscription level
- Managed identities preferred over service principals
- Groups over individual user assignments
- Scope to minimum necessary (resource group vs subscription)

### Privileged Identity Management (PIM)

| Role | Eligible Users | Activation Duration | Approval Required | MFA Required |
|------|---------------|---------------------|-------------------|--------------|
| Global Administrator | Break-glass accounts only | 1 hour | Yes | Yes |
| Subscription Owner | Platform team | 4 hours | Yes | Yes |
| Subscription Contributor | DevOps team | 8 hours | No | Yes |
| Security Administrator | Security team | 8 hours | No | Yes |

See [pim-configuration.md](pim-configuration.md) for full configuration.

## Validation Tests

### Test 1: MFA Enforcement

**Objective:** Verify MFA is required for all users

**Steps:**
1. Sign in with test account (no MFA registered)
2. Expected: Prompted to register MFA
3. Sign in with MFA-registered account
4. Expected: MFA challenge presented

**Evidence:** [View screenshot](evidence/test-mfa-enforcement.png)

### Test 2: Legacy Auth Blocked

**Objective:** Verify legacy authentication is blocked

**Steps:**
1. Attempt IMAP/POP3 connection to Exchange Online
2. Expected: Connection rejected
3. Check sign-in logs for blocked event

**Evidence:** [View screenshot](evidence/test-legacy-auth-blocked.png)

### Test 3: PIM Activation

**Objective:** Verify JIT access works correctly

**Steps:**
1. Request Contributor role activation via PIM
2. Complete MFA challenge
3. Wait for approval (if configured)
4. Verify role is active and time-limited
5. After expiration, verify role is deactivated

**Evidence:** [View screenshot](evidence/test-pim-activation.png)

## Monitoring & Detection

### KQL Queries for Sign-in Monitoring

```kql
// Failed sign-ins in last 24 hours
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != 0
| summarize FailureCount = count() by UserPrincipalName, ResultDescription
| order by FailureCount desc

// Legacy auth attempts
SigninLogs
| where TimeGenerated > ago(24h)
| where ClientAppUsed in ("Exchange ActiveSync", "IMAP4", "POP3", "MAPI Over HTTP", "Other clients")
| summarize AttemptCount = count() by UserPrincipalName, ClientAppUsed

// High-risk sign-ins
SigninLogs
| where TimeGenerated > ago(24h)
| where RiskLevelDuringSignIn in ("high", "medium")
| project TimeGenerated, UserPrincipalName, RiskLevelDuringSignIn, Location, IPAddress
```

### Sentinel Analytics Rules

See [../monitoring-and-response/runbooks/](../monitoring-and-response/runbooks/) for response procedures.

## Related Documentation

- [Conditional Access Policies](conditional-access-policies.md)
- [RBAC Assignments](rbac-assignments.md)
- [PIM Configuration](pim-configuration.md)
- [Controls Matrix](../docs/controls-matrix.md)
- [Threat Model - Identity Section](../docs/threat-model.md#component-entra-id-identity-provider)

## Implementation Checklist

- [ ] Conditional Access: Require MFA for all users
- [ ] Conditional Access: Block legacy authentication
- [ ] Conditional Access: Risk-based policies
- [ ] RBAC: Review and document all role assignments
- [ ] RBAC: Remove unnecessary Owner/Contributor access
- [ ] PIM: Configure eligible roles
- [ ] PIM: Set activation requirements (MFA, approval)
- [ ] Monitoring: Sign-in log queries in Log Analytics
- [ ] Monitoring: Sentinel analytics rules deployed
- [ ] Evidence: Screenshots captured for all controls
- [ ] Validation: All test cases executed and documented
