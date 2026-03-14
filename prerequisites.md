# Workshop Prerequisites

Use this guide before starting a read-only Azure Firewall flow-log workshop.

This workflow is for discovery, analysis, and review-only draft generation. It must not be used to deploy Azure resources, change Azure Firewall rules, or execute remediation commands during the workshop.

## Supported operator context

- Windows workstation
- VS Code workspace opened for this repository
- Customer environment where Azure access must remain read-only

## Required local tools

### Azure CLI

Install Azure CLI on Windows if it is not already available.

```powershell
winget install --exact --id Microsoft.AzureCLI
```

After installation, close and reopen any active terminal before using `az`.

Verify the installation:

```powershell
az --version
```

### Log Analytics query capability

This workflow requires Azure CLI support for Log Analytics queries through `az monitor log-analytics query`.

Validate that the query command is available:

```powershell
az monitor log-analytics query --help
```

If Azure CLI prompts to install extension-backed support for the command, allow that install before continuing. If you want Azure CLI to prompt automatically when an extension-backed command is missing, set:

```powershell
az config set extension.use_dynamic_install=yes_prompt
```

You can review installed extensions with:

```powershell
az extension list --output table
```

## Recommended VS Code extensions

These extensions are recommended for workshop execution and review, but the required Log Analytics query capability comes from Azure CLI rather than a dedicated Azure Monitor VS Code extension.

- `github.copilot`
- `ms-azuretools.vscode-azureresourcegroups`
- `ms-azuretools.vscode-bicep`

Optional install commands:

```powershell
code --install-extension github.copilot
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension ms-azuretools.vscode-bicep
```

## Required Azure access model

Use a least-privilege read-only user or managed identity.

Minimum required access:

- read access to the intended Azure tenant
- read access to candidate subscriptions used for discovery
- read access to the selected Log Analytics workspace or candidate workspaces
- permission to run Log Analytics queries

Do not use an owner, contributor, or other broad write-capable identity unless the customer has explicitly accepted that risk outside the workshop workflow.

## Mandatory Azure logout and login reset

Start every workshop with a full Azure logout and login reset so stale tenant or subscription state does not bleed into discovery.

1. Run:

```powershell
az logout
```

2. Close all active terminals.
3. Open a fresh terminal.
4. Sign in again to the intended tenant.

Interactive sign-in example:

```powershell
az login --tenant <tenant-id-or-domain>
```

Managed identity example:

```powershell
az login --identity
```

5. Verify the active context:

```powershell
az account show --output table
```

If discovery needs to span multiple subscriptions in the same tenant, keep the session tenant-correct first and set the specific subscription only when the workflow needs it.

## Tenant and tool-context validation

Before discovery starts, confirm all of the following:

- Azure CLI is signed into the intended tenant
- Azure CLI is using the intended read-only identity
- any extension-backed or MCP-backed Azure tooling matches the same tenant and subscription context as Azure CLI

Treat any context mismatch as a blocking issue. Fix the Azure context before trusting discovery results or Log Analytics query output.

## Read-only operating rules

- do not deploy Azure resources during the workshop
- do not change Azure Firewall rules during the workshop
- do not execute remediation or enablement commands during the workshop
- keep all generated firewall outputs review-only and approval-pending

## Pre-workshop checklist

Complete this checklist before running `/01-start-workshop`:

1. Azure CLI is installed and `az --version` succeeds.
2. `az monitor log-analytics query --help` succeeds.
3. Recommended VS Code extensions are installed if the operator wants extension-backed Azure browsing.
4. The operator performed a full `az logout` and started a fresh terminal.
5. The operator signed back into the intended tenant only.
6. The active identity is a least-privilege read-only user or managed identity.
7. Any extension-backed or MCP-backed Azure tooling matches Azure CLI tenant and subscription context.

## Stop and fix setup if

- `az` is not installed or not on the path
- `az monitor log-analytics query` is unavailable
- the active tenant is not the intended tenant
- the active identity is not the intended read-only identity
- non-CLI Azure tooling does not match Azure CLI context