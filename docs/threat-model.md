# Threat Model

This document uses the **STRIDE** methodology to identify threats against the Azure security baseline architecture.

## STRIDE Categories

| Category | Description | Question to Ask |
|----------|-------------|-----------------|
| **S**poofing | Impersonating something or someone | Can an attacker pretend to be a legitimate user/system? |
| **T**ampering | Modifying data or code | Can an attacker modify data in transit or at rest? |
| **R**epudiation | Denying actions | Can an attacker (or user) deny performing an action? |
| **I**nformation Disclosure | Exposing data | Can an attacker access data they shouldn't? |
| **D**enial of Service | Disrupting service | Can an attacker make the system unavailable? |
| **E**levation of Privilege | Gaining unauthorized access | Can an attacker gain higher privileges? |

---

## Component: Entra ID (Identity Provider)

### Spoofing
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Credential theft via phishing | High | High | MFA via Conditional Access | ⬜ |
| Session hijacking | Medium | High | Continuous access evaluation, token lifetime policies | ⬜ |
| Service principal impersonation | Medium | High | Certificate-based auth, federated credentials | ⬜ |

### Tampering
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Token manipulation | Low | High | Token validation, short-lived tokens | ⬜ |
| Group membership tampering | Medium | Medium | PIM for group management, audit logs | ⬜ |

### Repudiation
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Deny administrative actions | Medium | Medium | Entra ID audit logs → Log Analytics → Sentinel | ⬜ |
| Deny authentication events | Low | Low | Sign-in logs retention (90+ days) | ⬜ |

### Information Disclosure
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| User enumeration | Medium | Low | Restrict external collaboration settings | ⬜ |
| Token leakage | Medium | High | CAE, token binding, monitor for token replay | ⬜ |

### Denial of Service
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Authentication service unavailable | Low | High | Entra ID SLA, emergency access accounts | ⬜ |
| Account lockout attacks | Medium | Medium | Smart lockout policies | ⬜ |

### Elevation of Privilege
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Privilege escalation via role assignment | Medium | High | PIM with approval workflow, time-limited access | ⬜ |
| Consent grant attacks | Medium | High | Admin consent workflow, limit user consent | ⬜ |

---

## Component: Application Tier (App Service / AKS)

### Spoofing
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| API impersonation | Medium | High | Managed identity, certificate validation | ⬜ |
| Request spoofing | Medium | Medium | Input validation, origin checks | ⬜ |

### Tampering
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Code injection | Medium | High | Input validation, parameterized queries, WAF | ⬜ |
| Configuration tampering | Medium | High | Immutable infrastructure, GitOps | ⬜ |
| Container image tampering | Medium | High | Image signing, Defender for Containers | ⬜ |

### Repudiation
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Deny API calls | Medium | Medium | Application logging → Log Analytics | ⬜ |
| Deny data modifications | Medium | Medium | Audit trail in application + database | ⬜ |

### Information Disclosure
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Secrets in logs | High | High | Structured logging, secret masking | ⬜ |
| Error message leakage | Medium | Medium | Generic error responses, detailed logging server-side | ⬜ |
| Memory dump exposure | Low | High | Disable crash dumps in production | ⬜ |

### Denial of Service
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Resource exhaustion | Medium | Medium | Auto-scaling, rate limiting | ⬜ |
| Application-layer DDoS | Medium | High | WAF rate limiting, Azure DDoS Protection | ⬜ |

### Elevation of Privilege
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Container escape | Low | High | Pod security policies, Defender for Containers | ⬜ |
| Managed identity abuse | Medium | High | Least privilege RBAC for managed identity | ⬜ |

---

## Component: Data Tier (Azure SQL / Storage)

### Spoofing
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Database connection spoofing | Low | High | Private endpoint, managed identity auth | ⬜ |

### Tampering
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| SQL injection | Medium | High | Parameterized queries, Defender for SQL | ⬜ |
| Data modification by insider | Medium | Medium | Database audit logs, row-level security | ⬜ |
| Backup tampering | Low | High | Immutable backups, soft delete | ⬜ |

### Repudiation
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Deny data access | Medium | Medium | SQL audit logs → Log Analytics | ⬜ |
| Deny data modification | Medium | Medium | Change data capture, temporal tables | ⬜ |

### Information Disclosure
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Data exfiltration | Medium | High | Private endpoints, no public access | ⬜ |
| Backup exposure | Medium | High | Encrypted backups, RBAC on storage | ⬜ |
| Query result leakage | Medium | Medium | Data masking, column-level encryption | ⬜ |

### Denial of Service
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Database resource exhaustion | Medium | High | DTU/vCore limits, query timeout | ⬜ |
| Storage quota exhaustion | Medium | Medium | Monitoring, alerts, auto-growth limits | ⬜ |

### Elevation of Privilege
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| SQL privilege escalation | Low | High | Least privilege DB roles, no db_owner for apps | ⬜ |
| Cross-database access | Low | Medium | Contained databases, no cross-db queries | ⬜ |

---

## Component: Key Vault

### Spoofing
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Unauthorized secret access | Medium | High | RBAC, managed identity, access policies | ⬜ |

### Tampering
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Secret/key modification | Low | High | Soft delete, purge protection | ⬜ |

### Repudiation
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Deny secret access | Medium | Medium | Key Vault diagnostic logs | ⬜ |

### Information Disclosure
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Secret leakage via logs | Medium | High | Never log secret values, audit access only | ⬜ |
| Unauthorized key export | Low | High | Non-exportable keys, HSM-backed keys | ⬜ |

### Denial of Service
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| Key Vault throttling | Medium | Medium | Caching, multiple vaults, monitoring | ⬜ |

### Elevation of Privilege
| Threat | Likelihood | Impact | Mitigation | Status |
|--------|------------|--------|------------|--------|
| RBAC escalation to Key Vault | Medium | High | Separate Key Vault admin from users | ⬜ |

---

## Risk Summary Matrix

| Component | Highest Risks | Priority Mitigations |
|-----------|--------------|---------------------|
| Entra ID | Credential theft, privilege escalation | MFA, PIM, Conditional Access |
| Application | Code injection, secrets exposure | WAF, managed identity, input validation |
| Data | SQL injection, exfiltration | Private endpoints, Defender, audit logs |
| Key Vault | Unauthorized access | RBAC, access policies, logging |

---

## Threat Model Review Schedule

| Review Type | Frequency | Trigger |
|-------------|-----------|---------|
| Scheduled review | Quarterly | Calendar |
| Change-triggered | As needed | New feature, architecture change |
| Incident-triggered | As needed | Security incident post-mortem |

**Last reviewed:** [DATE]  
**Next review:** [DATE]  
**Reviewed by:** [NAME]
