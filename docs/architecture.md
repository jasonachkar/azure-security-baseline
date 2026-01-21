# Architecture Documentation

## Overview

This document describes the security architecture implemented in this baseline, including trust boundaries, data flows, and security controls at each layer.

## Architecture Diagram

```
                                    ┌──────────────────────────────────────┐
                                    │           INTERNET                   │
                                    └──────────────────┬───────────────────┘
                                                       │
                                    ┌──────────────────▼───────────────────┐
                                    │      Azure Front Door / WAF          │
                                    │   ─────────────────────────────────  │
                                    │   • DDoS Protection                  │
                                    │   • OWASP Rule Sets                  │
                                    │   • Rate Limiting                    │
                                    └──────────────────┬───────────────────┘
                                                       │
┌──────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┐
│                                              AZURE TENANT                                                     │
│  ┌───────────────────────────────────────────────────┼────────────────────────────────────────────────────┐  │
│  │                                       TRUST BOUNDARY: SUBSCRIPTION                                      │  │
│  │                                                   │                                                     │  │
│  │   ┌───────────────────────────────────────────────▼────────────────────────────────────────────────┐   │  │
│  │   │                              VNET: hub-vnet (10.0.0.0/16)                                       │   │  │
│  │   │  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────────────────────────┐ │   │  │
│  │   │  │  subnet-bastion     │  │  subnet-firewall    │  │  subnet-gateway                         │ │   │  │
│  │   │  │  10.0.1.0/26        │  │  10.0.2.0/26        │  │  10.0.3.0/27                            │ │   │  │
│  │   │  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │                                         │ │   │  │
│  │   │  │  │ Azure Bastion │  │  │  │ Azure FW      │  │  │  VPN/ExpressRoute GW                    │ │   │  │
│  │   │  │  └───────────────┘  │  │  └───────┬───────┘  │  │                                         │ │   │  │
│  │   │  └─────────────────────┘  └──────────┼──────────┘  └─────────────────────────────────────────┘ │   │  │
│  │   └──────────────────────────────────────┼─────────────────────────────────────────────────────────┘   │  │
│  │                                          │ VNET PEERING                                                │  │
│  │   ┌──────────────────────────────────────▼─────────────────────────────────────────────────────────┐   │  │
│  │   │                              VNET: spoke-vnet (10.1.0.0/16)                                     │   │  │
│  │   │                                                                                                 │   │  │
│  │   │  ┌─────────────────────────────┐  ┌─────────────────────────────┐  ┌─────────────────────────┐ │   │  │
│  │   │  │  subnet-app (10.1.1.0/24)   │  │  subnet-data (10.1.2.0/24)  │  │  subnet-pe (10.1.3.0/24)│ │   │  │
│  │   │  │  NSG: nsg-app               │  │  NSG: nsg-data              │  │  Private Endpoints      │ │   │  │
│  │   │  │  ┌───────────────────────┐  │  │  ┌───────────────────────┐  │  │  ┌───────────────────┐  │ │   │  │
│  │   │  │  │ App Service / AKS    │  │  │  │ Azure SQL / Cosmos    │  │  │  │ Key Vault PE      │  │ │   │  │
│  │   │  │  │ (Managed Identity)   │◄─┼──┼──┤ (Private Endpoint)    │  │  │  │ Storage PE        │  │ │   │  │
│  │   │  │  └───────────────────────┘  │  │  └───────────────────────┘  │  │  └───────────────────┘  │ │   │  │
│  │   │  └─────────────────────────────┘  └─────────────────────────────┘  └─────────────────────────┘ │   │  │
│  │   └─────────────────────────────────────────────────────────────────────────────────────────────────┘   │  │
│  │                                                                                                         │  │
│  │   ┌─────────────────────────────────────────────────────────────────────────────────────────────────┐   │  │
│  │   │                              SECURITY SERVICES                                                   │   │  │
│  │   │  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────────┐ │   │  │
│  │   │  │ Key Vault         │  │ Log Analytics     │  │ Defender for      │  │ Microsoft Sentinel    │ │   │  │
│  │   │  │ (Secrets/Keys)    │  │ Workspace         │  │ Cloud             │  │ (SIEM/SOAR)           │ │   │  │
│  │   │  └───────────────────┘  └───────────────────┘  └───────────────────┘  └───────────────────────┘ │   │  │
│  │   └─────────────────────────────────────────────────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                              ENTRA ID (Identity Layer)                                                   │  │
│  │  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────────────────┐ │  │
│  │  │ Conditional       │  │ Privileged        │  │ Entra ID          │  │ App Registrations             │ │  │
│  │  │ Access Policies   │  │ Identity Mgmt     │  │ Protection        │  │ (Service Principals)          │ │  │
│  │  └───────────────────┘  └───────────────────┘  └───────────────────┘  └───────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Trust Boundaries

### Boundary 1: Internet → Azure (Perimeter)

**Threats:** DDoS, application-layer attacks, credential stuffing, bot attacks

**Controls:**
- Azure Front Door with WAF (OWASP 3.2 ruleset)
- DDoS Protection Standard
- Rate limiting policies
- Geographic restrictions (if applicable)

### Boundary 2: Azure → Subscription (Tenant)

**Threats:** Cross-tenant attacks, management plane compromise, privilege escalation

**Controls:**
- Entra ID Conditional Access (MFA, compliant device, location)
- Privileged Identity Management (JIT access)
- Azure RBAC with least privilege
- Management group policies

### Boundary 3: Subscription → Workload VNETs (Network)

**Threats:** Lateral movement, data exfiltration, unauthorized access

**Controls:**
- Hub-spoke network topology
- NSG deny-by-default rules
- Azure Firewall for egress filtering
- Private endpoints for PaaS services
- No public IPs on workloads

### Boundary 4: Application → Data (Application)

**Threats:** SQL injection, data leakage, credential exposure

**Controls:**
- Managed identity (no credentials in code)
- Key Vault for secrets
- Private endpoints for data services
- TLS 1.2+ enforcement
- Defender for SQL threat detection

## Data Flows

### Flow 1: User Authentication

```
User → Entra ID → Conditional Access evaluation → MFA challenge → Token issued → Application
```

### Flow 2: Application to Database

```
App Service → Managed Identity → Key Vault (connection string) → Private Endpoint → Azure SQL
```

### Flow 3: Security Monitoring

```
All resources → Diagnostic Settings → Log Analytics → Sentinel Analytics Rules → Incidents → Runbooks
```

## Security Layers Summary

| Layer | Primary Controls | Monitoring |
|-------|-----------------|------------|
| Perimeter | WAF, DDoS Protection | Front Door logs, WAF alerts |
| Identity | Conditional Access, MFA, PIM | Sign-in logs, Risk detections |
| Network | NSG, Private Endpoints, Firewall | NSG flow logs, Firewall logs |
| Application | Managed Identity, Key Vault | App Insights, Key Vault logs |
| Data | Encryption, Defender for SQL | SQL audit logs, Defender alerts |

## Deployment Regions

| Resource Type | Primary Region | DR Region (if applicable) |
|--------------|----------------|---------------------------|
| Compute | Canada Central | Canada East |
| Data | Canada Central | Canada East (geo-replication) |
| Key Vault | Canada Central | — (soft delete enabled) |
| Log Analytics | Canada Central | — |

## Assumptions & Constraints

1. Single subscription deployment (adapt for enterprise scale with management groups)
2. No hybrid connectivity shown (add VPN/ExpressRoute as needed)
3. Assumes P1 or P2 Entra ID license for Conditional Access and PIM
4. Defender for Cloud Standard tier enabled
