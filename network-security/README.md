# Network Security

This section documents the network security controls implemented in this security baseline.

## Overview

Network security implements defense-in-depth through segmentation, private connectivity, and traffic filtering:

1. **NSGs** — Deny-by-default network access control
2. **Private Endpoints** — Private connectivity to PaaS services
3. **Azure Firewall** — Centralized egress filtering (optional)
4. **Network Segmentation** — Hub-spoke topology with isolation

## Controls Implemented

### Network Security Groups (NSGs)

| NSG Name | Attached To | Default Rule | Custom Rules |
|----------|-------------|--------------|--------------|
| nsg-app | subnet-app | Deny all inbound | Allow 443 from Front Door |
| nsg-data | subnet-data | Deny all inbound | Allow 1433 from subnet-app only |
| nsg-bastion | subnet-bastion | Azure Bastion requirements | — |

See [nsg-rules.md](nsg-rules.md) for detailed rule definitions.

**Principles applied:**
- Deny all inbound by default
- Allow only required ports/protocols
- Source IP restrictions where possible
- Logging enabled for all NSGs

### Private Endpoints

| Resource | Private Endpoint | Private DNS Zone | Public Access |
|----------|-----------------|------------------|---------------|
| Azure SQL | pe-sql-workload | privatelink.database.windows.net | Disabled |
| Key Vault | pe-kv-workload | privatelink.vaultcore.azure.net | Disabled |
| Storage Account | pe-st-workload | privatelink.blob.core.windows.net | Disabled |

See [private-endpoints.md](private-endpoints.md) for configuration details.

### Network Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│ Hub VNET (10.0.0.0/16)                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │ Bastion     │  │ Firewall    │  │ Gateway         │  │
│  │ 10.0.1.0/26 │  │ 10.0.2.0/26 │  │ 10.0.3.0/27     │  │
│  └─────────────┘  └──────┬──────┘  └─────────────────┘  │
└──────────────────────────┼──────────────────────────────┘
                           │ Peering
┌──────────────────────────▼──────────────────────────────┐
│ Spoke VNET (10.1.0.0/16)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │ App Subnet  │  │ Data Subnet │  │ PE Subnet       │  │
│  │ 10.1.1.0/24 │  │ 10.1.2.0/24 │  │ 10.1.3.0/24     │  │
│  │ NSG: nsg-app│  │ NSG: nsg-data│ │ Private Endpts  │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Validation Tests

### Test 1: NSG Deny-by-Default

**Objective:** Verify inbound traffic is blocked by default

**Steps:**
1. Attempt SSH/RDP to VM from internet
2. Expected: Connection timeout
3. Check NSG flow logs for denied traffic

**Evidence:** [View screenshot](evidence/test-nsg-deny.png)

### Test 2: Private Endpoint Connectivity

**Objective:** Verify PaaS services are accessible only via private endpoint

**Steps:**
1. From application subnet, resolve SQL FQDN
2. Expected: Private IP returned (10.1.3.x)
3. Test connection via private IP
4. Attempt public endpoint access
5. Expected: Public access denied/timeout

**Evidence:** [View screenshot](evidence/test-private-endpoint.png)

### Test 3: Cross-Subnet Traffic

**Objective:** Verify traffic between subnets follows NSG rules

**Steps:**
1. From app subnet, connect to data subnet on port 1433
2. Expected: Connection succeeds
3. From app subnet, connect to data subnet on port 22
4. Expected: Connection blocked

**Evidence:** [View screenshot](evidence/test-cross-subnet.png)

## Monitoring & Detection

### KQL Queries for Network Monitoring

```kql
// Denied traffic in last 24 hours
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(24h)
| where FlowStatus_s == "D"
| summarize DeniedCount = count() by SrcIP_s, DestIP_s, DestPort_d, NSGRule_s
| order by DeniedCount desc

// Traffic to/from public IPs
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(24h)
| where not(ipv4_is_private(SrcIP_s)) or not(ipv4_is_private(DestIP_s))
| summarize Count = count() by SrcIP_s, DestIP_s, DestPort_d
| order by Count desc

// Private endpoint connections
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where ResourceType == "PRIVATEENDPOINTS"
| project TimeGenerated, Resource, OperationName, properties_s
```

## Related Documentation

- [NSG Rules](nsg-rules.md)
- [Private Endpoints](private-endpoints.md)
- [Controls Matrix](../docs/controls-matrix.md)
- [Architecture](../docs/architecture.md)

## Implementation Checklist

- [ ] NSGs: Created with deny-all-inbound default
- [ ] NSGs: Custom rules documented and justified
- [ ] NSGs: Flow logging enabled
- [ ] Private Endpoints: Configured for all PaaS services
- [ ] Private DNS: Zones created and linked to VNET
- [ ] Public Access: Disabled on all PaaS services
- [ ] Monitoring: NSG flow log queries in Log Analytics
- [ ] Evidence: Screenshots captured for all controls
- [ ] Validation: All test cases executed and documented
