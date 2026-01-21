# Brute Force Attack Response Runbook

## Alert Details

| Field | Value |
|-------|-------|
| **Source** | Microsoft Sentinel |
| **Rule Name** | Multiple failed sign-ins followed by success |
| **Severity** | High |
| **MITRE Tactic** | Credential Access (TA0006) |
| **MITRE Technique** | Brute Force (T1110) |

## Description

This alert fires when a user account experiences multiple failed sign-in attempts (>10 in 5 minutes) followed by a successful sign-in. This pattern is indicative of a brute force or password spray attack that may have succeeded.

## Triage Steps

### Step 1: Verify the Alert (5 min)

1. Open the Sentinel incident
2. Review the timeline of events
3. Note:
   - User principal name (UPN)
   - Source IP address(es)
   - User agent strings
   - Time of successful sign-in
   - Geographic location

### Step 2: Assess Risk (5 min)

Answer these questions:

- [ ] Is this a privileged account (admin, service account)?
- [ ] Is the source IP known/expected?
- [ ] Is the location consistent with user's normal pattern?
- [ ] Did the user travel recently (possible false positive)?
- [ ] Are multiple accounts affected (password spray)?

**If privileged account or multiple accounts affected → Escalate immediately**

## Investigation Queries

### Query 1: Get Full Sign-in History

```kql
SigninLogs
| where TimeGenerated > ago(24h)
| where UserPrincipalName == "<USER_UPN>"
| project TimeGenerated, 
          ResultType, 
          ResultDescription, 
          IPAddress, 
          Location, 
          UserAgent,
          ConditionalAccessStatus,
          RiskLevelDuringSignIn
| order by TimeGenerated desc
```

### Query 2: Check for Password Spray (Multiple Users from Same IP)

```kql
SigninLogs
| where TimeGenerated > ago(1h)
| where IPAddress == "<SOURCE_IP>"
| summarize 
    FailedAttempts = countif(ResultType != 0),
    SuccessfulAttempts = countif(ResultType == 0),
    UniqueUsers = dcount(UserPrincipalName)
    by IPAddress
| where UniqueUsers > 5
```

### Query 3: Check User's Recent Activity

```kql
// Azure Activity
AzureActivity
| where TimeGenerated > ago(24h)
| where Caller contains "<USER_UPN>"
| project TimeGenerated, OperationNameValue, ResourceGroup, CallerIpAddress

// Entra ID Audit
AuditLogs
| where TimeGenerated > ago(24h)
| where InitiatedBy.user.userPrincipalName == "<USER_UPN>"
| project TimeGenerated, OperationName, Result
```

## Containment Actions

### If Attack Confirmed (Suspicious IP, Location, or Behavior)

**Immediate (within 15 minutes):**

1. **Revoke user sessions**
   ```powershell
   # Azure AD PowerShell
   Revoke-AzureADUserAllRefreshToken -ObjectId <USER_OBJECT_ID>
   ```
   
   Or via Azure Portal:
   - Entra ID → Users → Select user → Revoke sessions

2. **Force password reset**
   - Entra ID → Users → Select user → Reset password
   - Enable "Require user to change password at next sign-in"

3. **Block sign-in (if necessary)**
   - Entra ID → Users → Select user → Edit properties → Block sign-in

4. **Block source IP (if malicious)**
   - Add to Conditional Access named location (blocked)
   - Or add to Azure Firewall deny list

### If Multiple Accounts Affected (Password Spray)

1. Block the source IP immediately
2. Identify all affected accounts
3. Force password reset for all affected accounts
4. Consider enabling temporary sign-in risk policy

## Remediation Steps

### After Containment

1. **Review account for compromise indicators:**
   - Check Inbox rules (forwarding, auto-delete)
   - Check OAuth app consent grants
   - Check MFA registration changes
   - Check device registrations

2. **Review permissions:**
   - Azure RBAC assignments
   - Entra ID role memberships
   - Application permissions

3. **Strengthen account security:**
   - Ensure MFA is enrolled
   - Consider FIDO2 or passwordless
   - Apply Conditional Access policy requiring compliant device

## Escalation Criteria

Escalate to Incident Commander if:

- [ ] Privileged account compromised
- [ ] More than 5 accounts affected
- [ ] Evidence of data access post-compromise
- [ ] Attacker has persistent access (backdoor, OAuth app)
- [ ] Attack is ongoing and spreading

## Communication Templates

### For User Notification

```
Subject: Security Alert - Password Reset Required

Your account [UPN] experienced suspicious sign-in activity. As a precaution, 
your password has been reset and sessions revoked.

Actions required:
1. Reset your password at https://aka.ms/sspr
2. Review your recent account activity
3. Report any unrecognized activity to [security team email]

If you did not attempt to sign in from [location/IP], please contact us immediately.
```

### For Management Notification (if escalated)

```
Subject: Security Incident - Brute Force Attack [Confirmed/Suspected]

Summary: [Account(s)] experienced brute force attack with [suspected/confirmed] 
compromise at [time].

Impact: [Description of potential impact]

Status: [Contained/Investigating/Remediated]

Actions Taken:
- [List actions]

Next Steps:
- [List next steps]

ETA for Resolution: [Time estimate]
```

## Post-Incident

### Within 24 Hours

- [ ] Document all actions taken in incident ticket
- [ ] Collect and preserve logs
- [ ] Update user on status

### Within 72 Hours

- [ ] Complete incident report
- [ ] Identify root cause (weak password, no MFA, etc.)
- [ ] Recommend security improvements
- [ ] Update detection rules if needed

### Lessons Learned

Document:
- What worked well
- What could be improved
- Detection gaps identified
- Recommended security controls

## Related Documentation

- [Identity & Access Controls](../../identity-and-access/README.md)
- [Conditional Access Policies](../../identity-and-access/conditional-access-policies.md)
- [Controls Matrix](../../docs/controls-matrix.md)

---

**Last Updated:** [DATE]  
**Owner:** [Security Team]  
**Review Frequency:** Quarterly
