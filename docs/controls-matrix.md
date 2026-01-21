# Security Controls Matrix

This matrix maps security controls to the risks they mitigate, the Azure features implementing them, and the evidence/detection/response for each.

## How to Use This Matrix

1. **Risk** — What bad thing are we preventing?
2. **Control** — What security measure addresses it?
3. **Azure Feature** — How is it implemented in Azure?
4. **Evidence** — Proof the control is working
5. **Detection** — How we know if it fails or is bypassed
6. **Runbook** — What to do when detection fires

---

## Identity & Access Management

| Risk | Control | Azure Feature | Evidence | Detection | Runbook |
|------|---------|---------------|----------|-----------|---------|
| Credential theft via phishing | Require MFA for all users | Conditional Access Policy | [CA-MFA-Policy.png](../identity-and-access/evidence/CA-MFA-Policy.png) | `SigninLogs \| where ResultType != 0 and AuthenticationRequirement == "multiFactorAuthentication"` | [mfa-failure-runbook.md](../monitoring-and-response/runbooks/mfa-failure-runbook.md) |
| Privilege escalation | Just-in-time access for admin roles | Privileged Identity Management (PIM) | [PIM-config.png](../identity-and-access/evidence/PIM-config.png) | `AuditLogs \| where OperationName contains "PIM"` | [pim-escalation-runbook.md](../monitoring-and-response/runbooks/pim-escalation-runbook.md) |
| Overprivileged accounts | Least privilege RBAC | Azure RBAC + Custom Roles | [RBAC-assignments.png](../identity-and-access/evidence/RBAC-assignments.png) | Quarterly access review | [access-review-runbook.md](../monitoring-and-response/runbooks/access-review-runbook.md) |
| Compromised legacy auth | Block legacy authentication | Conditional Access Policy | [CA-block-legacy.png](../identity-and-access/evidence/CA-block-legacy.png) | `SigninLogs \| where ClientAppUsed in ("Exchange ActiveSync", "Other clients")` | [legacy-auth-runbook.md](../monitoring-and-response/runbooks/legacy-auth-runbook.md) |
| Impossible travel attacks | Risk-based Conditional Access | Entra ID Protection | [CA-risk-policy.png](../identity-and-access/evidence/CA-risk-policy.png) | `AADUserRiskEvents` | [risky-signin-runbook.md](../monitoring-and-response/runbooks/risky-signin-runbook.md) |

---

## Network Security

| Risk | Control | Azure Feature | Evidence | Detection | Runbook |
|------|---------|---------------|----------|-----------|---------|
| Lateral movement | Network segmentation | NSG + deny-by-default | [NSG-rules.png](../network-security/evidence/NSG-rules.png) | `AzureNetworkAnalytics_CL \| where FlowStatus_s == "D"` | [blocked-traffic-runbook.md](../monitoring-and-response/runbooks/blocked-traffic-runbook.md) |
| Data exfiltration via public endpoint | Private connectivity | Private Endpoints + Private DNS | [private-endpoint.png](../network-security/evidence/private-endpoint.png) | `AzureDiagnostics \| where ResourceType == "PRIVATEENDPOINTS"` | [endpoint-config-drift-runbook.md](../monitoring-and-response/runbooks/endpoint-config-drift-runbook.md) |
| Unauthorized inbound access | Deny all inbound by default | NSG inbound rules | [NSG-inbound-deny.png](../network-security/evidence/NSG-inbound-deny.png) | NSG flow logs | [unauthorized-access-runbook.md](../monitoring-and-response/runbooks/unauthorized-access-runbook.md) |
| Management plane exposure | Restrict management access | Azure Bastion / JIT VM Access | [bastion-config.png](../network-security/evidence/bastion-config.png) | `AzureActivity \| where OperationName contains "JIT"` | [jit-access-runbook.md](../monitoring-and-response/runbooks/jit-access-runbook.md) |

---

## Secrets Management

| Risk | Control | Azure Feature | Evidence | Detection | Runbook |
|------|---------|---------------|----------|-----------|---------|
| Secrets in code | Externalize secrets | Azure Key Vault | [keyvault-config.png](../secrets-management/evidence/keyvault-config.png) | Repo scanning (pre-commit hooks) | [secret-leak-runbook.md](../monitoring-and-response/runbooks/secret-leak-runbook.md) |
| Secrets in environment variables | Use managed identity | Managed Identity + Key Vault | [managed-identity.png](../secrets-management/evidence/managed-identity.png) | `AzureDiagnostics \| where ResourceType == "VAULTS"` | [keyvault-access-runbook.md](../monitoring-and-response/runbooks/keyvault-access-runbook.md) |
| Key/secret expiration | Rotation policy | Key Vault expiration alerts | [rotation-policy.png](../secrets-management/evidence/rotation-policy.png) | Key Vault expiration events | [secret-rotation-runbook.md](../monitoring-and-response/runbooks/secret-rotation-runbook.md) |
| Unauthorized secret access | Access policies + RBAC | Key Vault access policies | [keyvault-rbac.png](../secrets-management/evidence/keyvault-rbac.png) | `AzureDiagnostics \| where OperationName == "SecretGet"` | [unauthorized-secret-access-runbook.md](../monitoring-and-response/runbooks/unauthorized-secret-access-runbook.md) |

---

## Threat Protection

| Risk | Control | Azure Feature | Evidence | Detection | Runbook |
|------|---------|---------------|----------|-----------|---------|
| Unpatched vulnerabilities | Continuous assessment | Defender for Cloud | [defender-recommendations.png](../threat-protection/evidence/defender-recommendations.png) | Defender for Cloud alerts | [vulnerability-remediation-runbook.md](../monitoring-and-response/runbooks/vulnerability-remediation-runbook.md) |
| Malware/ransomware | Endpoint protection | Defender for Servers | [defender-servers.png](../threat-protection/evidence/defender-servers.png) | `SecurityAlert \| where AlertType contains "Malware"` | [malware-response-runbook.md](../monitoring-and-response/runbooks/malware-response-runbook.md) |
| Container vulnerabilities | Container scanning | Defender for Containers | [defender-containers.png](../threat-protection/evidence/defender-containers.png) | Container vulnerability alerts | [container-vuln-runbook.md](../monitoring-and-response/runbooks/container-vuln-runbook.md) |
| SQL injection | Database threat detection | Defender for SQL | [defender-sql.png](../threat-protection/evidence/defender-sql.png) | `AzureDiagnostics \| where Category == "SQLSecurityAuditEvents"` | [sql-threat-runbook.md](../monitoring-and-response/runbooks/sql-threat-runbook.md) |

---

## Monitoring & Response

| Risk | Control | Azure Feature | Evidence | Detection | Runbook |
|------|---------|---------------|----------|-----------|---------|
| Missed security events | Centralized logging | Log Analytics Workspace | [log-analytics.png](../monitoring-and-response/evidence/log-analytics.png) | Log ingestion alerts | [logging-gap-runbook.md](../monitoring-and-response/runbooks/logging-gap-runbook.md) |
| Slow incident response | Automated detection | Sentinel Analytics Rules | [sentinel-rules.png](../monitoring-and-response/evidence/sentinel-rules.png) | Sentinel incidents | [incident-response-runbook.md](../monitoring-and-response/runbooks/incident-response-runbook.md) |
| Alert fatigue | Tuned alerting | Sentinel + suppression rules | [alert-tuning.png](../monitoring-and-response/evidence/alert-tuning.png) | False positive rate tracking | [alert-tuning-runbook.md](../monitoring-and-response/runbooks/alert-tuning-runbook.md) |

---

## Compliance & Governance

| Risk | Control | Azure Feature | Evidence | Detection | Runbook |
|------|---------|---------------|----------|-----------|---------|
| Configuration drift | Policy enforcement | Azure Policy (Deny/Audit) | [policy-compliance.png](../policies/evidence/policy-compliance.png) | Policy compliance dashboard | [policy-violation-runbook.md](../monitoring-and-response/runbooks/policy-violation-runbook.md) |
| Shadow resources | Resource governance | Management Groups + Policy | [management-groups.png](../policies/evidence/management-groups.png) | `AzureActivity \| where OperationName contains "Create"` | [unauthorized-resource-runbook.md](../monitoring-and-response/runbooks/unauthorized-resource-runbook.md) |
| Cost overruns | Budget controls | Azure Cost Management | [budget-alerts.png](../policies/evidence/budget-alerts.png) | Budget threshold alerts | [cost-overrun-runbook.md](../monitoring-and-response/runbooks/cost-overrun-runbook.md) |

---

## Control Status Tracker

Use this section to track implementation progress:

| Domain | Total Controls | Implemented | Evidence Captured | Detection Active | Runbook Written |
|--------|---------------|-------------|-------------------|------------------|-----------------|
| Identity & Access | 5 | ⬜ | ⬜ | ⬜ | ⬜ |
| Network Security | 4 | ⬜ | ⬜ | ⬜ | ⬜ |
| Secrets Management | 4 | ⬜ | ⬜ | ⬜ | ⬜ |
| Threat Protection | 4 | ⬜ | ⬜ | ⬜ | ⬜ |
| Monitoring & Response | 3 | ⬜ | ⬜ | ⬜ | ⬜ |
| Compliance & Governance | 3 | ⬜ | ⬜ | ⬜ | ⬜ |

**Legend:** ⬜ Not started | 🟡 In progress | ✅ Complete
