# Current Azure Context Template

This file is intentionally sanitized for public publication.

Use it as a working template for a private customer run. Do not commit live tenant identifiers, subscription identifiers, workspace names, resource IDs, or customer-specific evidence back into the repository.

## Tenant

- `<tenant-id>`

## Existing flow-log setup in scope

Work with the existing virtual network flow logs in the selected subscription.

- Subscription name: `<subscription-name>`
- Subscription ID: `<subscription-id>`

## Existing Traffic Analytics workspace

- Workspace name: `<workspace-name>`
- Resource group: `<workspace-resource-group>`
- Workspace resource ID: `/subscriptions/<subscription-id>/resourceGroups/<workspace-resource-group>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>`

## Existing flow logs to use

- `<flow-log-name-1>`
- `<flow-log-name-2>`
- `<flow-log-name-3>`

## Covered VNets for analysis

- `/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name-1>`
- `/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name-2>`
- `/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name-3>`

## Operating mode

- Do not provision duplicate flow logs for already covered VNets.
- Use the existing workspace and flow logs for discovery.
- Do not modify Azure Firewall rules without explicit approval.

## Current evidence snapshot

- Baseline window: `<lookback-window>`
- Latest refresh window: `<latest-refresh-window>`
- Observed covered VNets: `<observed-vnet-list>`
- Observed active subnets: `<observed-subnet-list>`
- `NTARuleRecommendation` status: `<empty-or-populated>`
- Approval-pending candidate set location: `firewall-policy-rules.md`