# Azure Security Baseline

A production-ready security baseline for Azure environments, implementing defense-in-depth controls across identity, network, secrets, and threat protection domains.

## Overview

This repository contains infrastructure-as-code, security configurations, detection rules, and operational runbooks for establishing a secure Azure landing zone. Each control is mapped to specific risks and includes validation evidence.

## Architecture

![Architecture Diagram](docs/architecture.md)

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Tenant                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Entra ID      │  │  Management     │  │   Defender for  │  │
│  │   + Conditional │  │  Group          │  │   Cloud         │  │
│  │   Access + PIM  │  │  (Governance)   │  │   + Sentinel    │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                    │           │
│  ┌────────▼────────────────────▼────────────────────▼────────┐  │
│  │                    Subscription                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │  │
│  │  │ Resource Grp │  │ Resource Grp │  │  Log Analytics   │ │  │
│  │  │ (Workload)   │  │ (Security)   │  │  Workspace       │ │  │
│  │  │              │  │              │  │                  │ │  │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │  ┌────────────┐  │ │  │
│  │  │ │ App Svc/ │ │  │ │ Key      │ │  │  │ Sentinel   │  │ │  │
│  │  │ │ AKS/VMs  │ │  │ │ Vault    │ │  │  │ Analytics  │  │ │  │
│  │  │ └──────────┘ │  │ └──────────┘ │  │  │ Rules      │  │ │  │
│  │  │              │  │              │  │  └────────────┘  │ │  │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │                  │ │  │
│  │  │ │ NSG/     │ │  │ │ Private  │ │  │  ┌────────────┐  │ │  │
│  │  │ │ Firewall │ │  │ │ Endpoint │ │  │  │ Runbooks   │  │ │  │
│  │  │ └──────────┘ │  │ └──────────┘ │  │  └────────────┘  │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
azure-security-baseline/
├── docs/                          # Architecture, threat model, controls matrix
├── identity-and-access/           # Entra ID, RBAC, Conditional Access, PIM
├── network-security/              # NSGs, private endpoints, segmentation
├── secrets-management/            # Key Vault, managed identities
├── threat-protection/             # Defender for Cloud, Sentinel rules
├── monitoring-and-response/       # Log Analytics queries, runbooks
├── policies/                      # Azure Policy definitions
├── infra/                         # Terraform IaC
└── scripts/                       # Deployment, validation, sanitization
```

## Controls Summary

| Domain | Controls Implemented | Evidence |
|--------|---------------------|----------|
| Identity & Access | Conditional Access, RBAC least privilege, PIM | [View](identity-and-access/evidence/) |
| Network Security | NSG deny-by-default, private endpoints | [View](network-security/evidence/) |
| Secrets Management | Key Vault + managed identity, no secrets in code | [View](secrets-management/evidence/) |
| Threat Protection | Defender for Cloud, Sentinel analytics | [View](threat-protection/evidence/) |
| Monitoring & Response | Log Analytics, KQL queries, runbooks | [View](monitoring-and-response/evidence/) |

See [docs/controls-matrix.md](docs/controls-matrix.md) for full risk-to-control mapping.

## Quick Start

### Prerequisites

- Azure subscription with Owner or Contributor access
- Terraform >= 1.5.0
- Azure CLI >= 2.50.0

### Deployment

```bash
# Authenticate
az login

# Initialize Terraform
cd infra
terraform init

# Review plan
terraform plan -out=tfplan

# Apply (after review)
terraform apply tfplan
```

### Validation

```bash
# Run validation tests
./scripts/validate.sh
```

## Security Notice

This repository contains sanitized configurations. See [SECURITY.md](SECURITY.md) for:
- What has been redacted (tenant IDs, object IDs, subscription IDs)
- How to adapt templates for your environment
- Responsible disclosure process

## Author

**[Your Name]** — Security Engineer  
Building this baseline while pursuing AZ-500 certification to demonstrate practical Azure security implementation.

## License

MIT License - See [LICENSE](LICENSE) for details.
