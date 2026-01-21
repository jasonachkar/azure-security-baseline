# Threat Protection

This section documents the threat protection controls implemented in this security baseline.

## Overview

Threat protection provides continuous assessment, detection, and response capabilities:

1. **Defender for Cloud** — Cloud security posture management (CSPM)
2. **Defender Plans** — Workload protection (CWPP)
3. **Microsoft Sentinel** — SIEM and SOAR
4. **Threat Intelligence** — Indicators and threat feeds

## Controls Implemented

### Defender for Cloud Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| Secure Score | Monitored | Track security posture |
| Regulatory Compliance | Enabled (CIS, NIST) | Compliance reporting |
| Continuous Export | To Log Analytics | Centralized analysis |
| Auto-provisioning | Enabled | Consistent agent deployment |

### Defender Plans Enabled

| Plan | Scope | Key Capabilities |
|------|-------|------------------|
| Defender for Servers | All VMs | Vulnerability assessment, EDR |
| Defender for SQL | Azure SQL, SQL on VMs | SQL threat detection |
| Defender for Storage | Storage accounts | Malware scanning, anomaly detection |
| Defender for Key Vault | Key Vaults | Anomalous access detection |
| Defender for Containers | AKS | Image scanning, runtime protection |
| Defender for App Service | App Services | Attack detection |

See [defender-for-cloud-config.md](defender-for-cloud-config.md) for detailed settings.

### Microsoft Sentinel

| Component | Configuration |
|-----------|---------------|
| Workspace | Connected to Log Analytics |
| Data Connectors | Azure AD, Azure Activity, Defender for Cloud, NSG Flow Logs |
| Analytics Rules | See [sentinel-analytics-rules/](sentinel-analytics-rules/) |
| Automation | Playbooks for common incidents |

## Analytics Rules Deployed

| Rule Name | Severity | Description | MITRE Tactic |
|-----------|----------|-------------|--------------|
| Brute force attack | High | Multiple failed sign-ins followed by success | Credential Access |
| Anomalous sign-in location | Medium | Sign-in from unusual location | Initial Access |
| Privileged role assigned | Medium | Global Admin or Owner assigned | Privilege Escalation |
| Mass file deletion | High | Large number of files deleted | Impact |
| Suspicious Key Vault access | High | Unusual Key Vault operations | Credential Access |

See [sentinel-analytics-rules/](sentinel-analytics-rules/) for rule definitions.

## Validation Tests

### Test 1: Defender Recommendations

**Objective:** Verify Defender for Cloud generates relevant recommendations

**Steps:**
1. Deploy intentionally misconfigured resource (e.g., storage with public access)
2. Wait for Defender assessment (can take hours)
3. Verify recommendation appears in Defender for Cloud
4. Remediate and verify recommendation resolves

**Evidence:** [View screenshot](evidence/test-defender-recommendation.png)

### Test 2: Threat Detection

**Objective:** Verify Defender detects simulated threats

**Steps:**
1. Trigger test alert (e.g., EICAR file for Defender for Storage)
2. Verify alert generated in Defender for Cloud
3. Verify alert forwarded to Sentinel
4. Verify incident created in Sentinel

**Evidence:** [View screenshot](evidence/test-threat-detection.png)

### Test 3: Sentinel Analytics Rule

**Objective:** Verify custom analytics rules fire correctly

**Steps:**
1. Generate activity matching rule criteria (e.g., multiple failed sign-ins)
2. Verify Sentinel incident created
3. Review incident details and entities
4. Test playbook execution (if configured)

**Evidence:** [View screenshot](evidence/test-sentinel-rule.png)

## Monitoring & Detection

### KQL Queries for Threat Monitoring

```kql
// High severity Defender alerts in last 24 hours
SecurityAlert
| where TimeGenerated > ago(24h)
| where AlertSeverity == "High"
| project TimeGenerated, AlertName, Description, RemediationSteps

// Sentinel incidents by severity
SecurityIncident
| where TimeGenerated > ago(7d)
| summarize Count = count() by Severity
| order by Severity

// Top attack techniques detected
SecurityAlert
| where TimeGenerated > ago(7d)
| extend Tactics = todynamic(Tactics)
| mv-expand Tactics
| summarize Count = count() by tostring(Tactics)
| order by Count desc
```

## Incident Response Integration

### Severity to Response Time SLA

| Severity | Initial Response | Resolution Target |
|----------|-----------------|-------------------|
| High | 15 minutes | 4 hours |
| Medium | 1 hour | 24 hours |
| Low | 4 hours | 72 hours |

### Escalation Path

1. **Automated** — Playbook runs (if configured)
2. **L1 SOC** — Initial triage and containment
3. **L2 Security** — Investigation and remediation
4. **Incident Commander** — Major incident coordination

See [../monitoring-and-response/runbooks/](../monitoring-and-response/runbooks/) for detailed procedures.

## Related Documentation

- [Defender for Cloud Config](defender-for-cloud-config.md)
- [Sentinel Analytics Rules](sentinel-analytics-rules/)
- [Controls Matrix](../docs/controls-matrix.md)
- [Threat Model](../docs/threat-model.md)

## Implementation Checklist

- [ ] Defender for Cloud: Enabled on subscription
- [ ] Defender Plans: Enabled for relevant workloads
- [ ] Defender: Auto-provisioning configured
- [ ] Defender: Continuous export to Log Analytics
- [ ] Sentinel: Workspace configured
- [ ] Sentinel: Data connectors enabled
- [ ] Sentinel: Analytics rules deployed
- [ ] Sentinel: Automation rules / playbooks configured
- [ ] Evidence: Screenshots captured for all controls
- [ ] Validation: All test cases executed and documented
