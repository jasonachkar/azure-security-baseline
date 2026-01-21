# Monitoring & Response

This section documents the monitoring, logging, and incident response capabilities implemented in this security baseline.

## Overview

Centralized monitoring enables detection, investigation, and response:

1. **Log Analytics Workspace** — Central log aggregation
2. **Diagnostic Settings** — Resource-level logging
3. **KQL Queries** — Detection and investigation
4. **Runbooks** — Documented response procedures

## Controls Implemented

### Log Analytics Workspace

| Setting | Value | Rationale |
|---------|-------|-----------|
| Retention | 90 days (hot), 2 years (archive) | Compliance + investigation needs |
| Daily Cap | Configured based on expected volume | Cost control |
| Access Control | RBAC, workspace-level | Least privilege |
| Commitment Tier | Based on daily ingestion | Cost optimization |

### Data Sources Connected

| Source | Log Type | Key Tables |
|--------|----------|------------|
| Entra ID | Sign-in, Audit | SigninLogs, AuditLogs |
| Azure Activity | Control plane | AzureActivity |
| NSG Flow Logs | Network traffic | AzureNetworkAnalytics_CL |
| Key Vault | Access logs | AzureDiagnostics |
| Defender for Cloud | Alerts | SecurityAlert |
| Azure SQL | Audit logs | AzureDiagnostics |
| App Service | Application logs | AppServiceHTTPLogs |

### Diagnostic Settings Template

All resources have diagnostic settings configured to send:
- **Audit logs** → Log Analytics
- **Metrics** → Log Analytics (if applicable)
- **Retention** → As per workspace configuration

## KQL Query Library

### Identity Queries

See [log-analytics-queries/identity-queries.kql](log-analytics-queries/identity-queries.kql)

```kql
// Failed sign-ins by user (potential brute force)
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != 0
| summarize FailedAttempts = count() by UserPrincipalName, bin(TimeGenerated, 1h)
| where FailedAttempts > 10
```

### Network Queries

See [log-analytics-queries/network-queries.kql](log-analytics-queries/network-queries.kql)

```kql
// Denied traffic by source
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(24h)
| where FlowStatus_s == "D"
| summarize DeniedFlows = count() by SrcIP_s
| order by DeniedFlows desc
| take 20
```

### Resource Queries

See [log-analytics-queries/resource-queries.kql](log-analytics-queries/resource-queries.kql)

```kql
// Resource modifications by user
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue contains "write" or OperationNameValue contains "delete"
| project TimeGenerated, Caller, OperationNameValue, ResourceGroup, _ResourceId
```

## Runbooks

Runbooks document the "If X, then Y" response procedures:

| Runbook | Trigger | Location |
|---------|---------|----------|
| MFA Failure Response | Multiple MFA failures | [runbooks/mfa-failure-runbook.md](runbooks/mfa-failure-runbook.md) |
| Brute Force Response | > 10 failed sign-ins | [runbooks/brute-force-runbook.md](runbooks/brute-force-runbook.md) |
| Privileged Access Alert | PIM activation / role assignment | [runbooks/privilege-escalation-runbook.md](runbooks/privilege-escalation-runbook.md) |
| Key Vault Anomaly | Unusual Key Vault access | [runbooks/keyvault-anomaly-runbook.md](runbooks/keyvault-anomaly-runbook.md) |
| Network Threat | Blocked malicious traffic | [runbooks/network-threat-runbook.md](runbooks/network-threat-runbook.md) |
| Malware Detection | Defender malware alert | [runbooks/malware-response-runbook.md](runbooks/malware-response-runbook.md) |

### Runbook Template

Each runbook follows this structure:

```markdown
# [Alert Name] Response Runbook

## Alert Details
- **Source:** [Sentinel / Defender / Custom]
- **Severity:** [High / Medium / Low]
- **MITRE Tactic:** [Tactic name]

## Triage Steps
1. [Step 1]
2. [Step 2]

## Investigation Queries
[KQL queries to investigate]

## Containment Actions
[Immediate actions to stop the threat]

## Remediation Steps
[Steps to fix the root cause]

## Escalation Criteria
[When to escalate]

## Post-Incident
[Documentation, lessons learned]
```

## Alert Configuration

### Alert Rules in Azure Monitor

| Alert | Condition | Severity | Action Group |
|-------|-----------|----------|--------------|
| High Secure Score drop | Secure Score < threshold | High | Security team email |
| Log ingestion stopped | No data for 1 hour | High | Platform team email |
| Key Vault access failure spike | > 10 failures in 5 min | Medium | Security team email |
| Defender high severity | Any high severity alert | High | Security team email + Teams |

## Validation Tests

### Test 1: Log Ingestion

**Objective:** Verify all expected logs are being collected

**Steps:**
1. Generate activity in each data source
2. Query Log Analytics for recent events
3. Verify events appear within expected latency
4. Check for any data gaps

**Evidence:** [View screenshot](evidence/test-log-ingestion.png)

### Test 2: Alert Firing

**Objective:** Verify alerts trigger correctly

**Steps:**
1. Create condition matching alert rule
2. Wait for alert evaluation period
3. Verify alert fires
4. Verify action group notification received

**Evidence:** [View screenshot](evidence/test-alert-firing.png)

### Test 3: Runbook Execution

**Objective:** Verify runbook is actionable

**Steps:**
1. Trigger test alert
2. Follow runbook steps
3. Verify each step is clear and executable
4. Document any gaps or improvements needed

**Evidence:** [View screenshot](evidence/test-runbook-execution.png)

## Dashboards

### Security Operations Dashboard

Key metrics:
- Open incidents by severity
- Mean time to detection (MTTD)
- Mean time to respond (MTTR)
- Top alert types
- Failed sign-ins trend
- Denied network traffic trend

See [dashboards/security-operations.json](dashboards/security-operations.json) for workbook definition.

## Related Documentation

- [Log Analytics Queries](log-analytics-queries/)
- [Runbooks](runbooks/)
- [Controls Matrix](../docs/controls-matrix.md)
- [Threat Protection](../threat-protection/README.md)

## Implementation Checklist

- [ ] Log Analytics: Workspace created with appropriate retention
- [ ] Diagnostic Settings: Configured for all resources
- [ ] Data Connectors: All sources connected
- [ ] KQL Queries: Library created and tested
- [ ] Runbooks: Written for all alert types
- [ ] Alerts: Configured in Azure Monitor
- [ ] Dashboards: Security operations workbook created
- [ ] Evidence: Screenshots captured for all controls
- [ ] Validation: All test cases executed and documented
