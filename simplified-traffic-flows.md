# Simplified traffic flow review checklist

This file is a sanitized checklist for reviewing customer traffic findings before approving any Azure Firewall rules.

Do not commit customer-specific workspace names, VNet names, subnet names, traffic volumes, or exposure details to the public repository. Keep those in private request artifacts.

## Scope

- source workspace: `<private-workspace-name>`
- evidence date: `<evidence-date>`
- evidence basis: recent `NTANetAnalytics` or equivalent flow-log data
- status: review only, no firewall changes applied

## How to use this file

For each flow below, confirm:

1. is it business required?
2. is the source correct?
3. is the destination correct?
4. is the port set minimal?
5. can it use service tags, FQDN rules, or private connectivity instead of broad IP rules?
6. should it be allowed, restricted further, or removed?

---

## Generic platform and outbound dependencies

| Flow | What to verify | Main ports |
| --- | --- | --- |
| `<workload-subnet> -> AzureMonitor` | monitoring and telemetry are expected | `443` |
| `<workload-subnet> -> AzureStorage` | logging, agent, or storage access is expected | `443` |
| `<workload-subnet> -> AzureEventHub` | event ingestion is expected | `5671` |
| `<workload-subnet> -> AzureCloud` | platform control-plane traffic is expected | platform-specific ports |
| `<workload-subnet> -> public endpoints` | any direct internet access is really needed | `80`, `443` |

## Generic internal traffic

| Flow | What to verify | Main ports |
| --- | --- | --- |
| `<subnet-a> -> <subnet-b>` | service-to-service communication is expected | `<validated-port-set>` |
| `<subnet-a> -> same VNet` | local service traffic is expected | internal only |

## Generic public inbound exposures to challenge

These are review items, not allow recommendations.

| Flow | What to verify | Main ports |
| --- | --- | --- |
| `Internet or Azure public -> <destination-subnet>` | whether public exposure is required at all | `<exposed-port-set>` |

---

## Suggested review decisions

Use one of these outcomes per row:

- `Approve as-is`
- `Approve but restrict source`
- `Approve but restrict destination`
- `Approve but reduce ports`
- `Replace with service tag or FQDN rule`
- `Replace with private endpoint or private path`
- `Reject / remove`

## Notes

- This file is a simplification layer for human review.
- The detailed reusable approval framework remains in [firewall-policy-rules.md](firewall-policy-rules.md).
- Do not implement Azure Firewall changes from this file alone without approval.