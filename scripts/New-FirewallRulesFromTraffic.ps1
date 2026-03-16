<#
.SYNOPSIS
    Query traffic → classify → prompt for high ports → output JSON for Bicep templates.

.DESCRIPTION
    Outputs two JSON files that feed directly into static Bicep templates:
      - firewall-rules.json  → infra/modules/firewall-observed-rules.bicep
      - nsg-rules.json       → infra/modules/nsg-observed-rules.bicep
    No Bicep string-building. The script is pure data processing.

.EXAMPLE
    ./scripts/New-FirewallRulesFromTraffic.ps1 -WorkspaceName 'my-workspace' -ResourceGroup 'my-rg'
.EXAMPLE
    ./scripts/New-FirewallRulesFromTraffic.ps1 -WorkspaceId 'abc-123'
#>
[CmdletBinding()]
param(
    [string]$WorkspaceId,
    [string]$WorkspaceName,
    [string]$ResourceGroup,

    [string]$Location = 'westeurope',
    [string]$Lookback = '7d',
    [int]$HighPortThreshold = 49152,
    [string]$OutputFolder,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve workspace ID from name if needed ─────────────────────────────────

if ([string]::IsNullOrWhiteSpace($WorkspaceId) -and -not [string]::IsNullOrWhiteSpace($WorkspaceName)) {
    Write-Host "Resolving workspace '$WorkspaceName' ..."
    $wsQuery = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        az monitor log-analytics workspace list --query "[?name=='$WorkspaceName'].customerId" --output tsv 2>&1
    } else {
        az monitor log-analytics workspace show --workspace-name $WorkspaceName --resource-group $ResourceGroup --query 'customerId' --output tsv 2>&1
    }
    if ($LASTEXITCODE -ne 0) { throw "Failed to resolve workspace '$WorkspaceName':`n$($wsQuery | Out-String)" }
    $WorkspaceId = ($wsQuery | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($WorkspaceId)) { throw "Workspace '$WorkspaceName' not found." }
    Write-Host "  Resolved to $WorkspaceId"
}

if ([string]::IsNullOrWhiteSpace($WorkspaceId)) {
    throw 'Provide either -WorkspaceId or -WorkspaceName (and optionally -ResourceGroup).'
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)

if ([string]::IsNullOrWhiteSpace($OutputFolder)) {
    $OutputFolder = Join-Path $repoRoot "requests/$(Get-Date -Format 'yyyyMMddTHHmmss')"
}
$queryResults = Join-Path $OutputFolder 'query-results'
New-Item -ItemType Directory -Path $queryResults -Force | Out-Null

# ── Helpers ──────────────────────────────────────────────────────────────────

function Test-IpInCidr ([string]$Ip, [string]$Cidr) {
    $parts = $Cidr -split '/'
    if ($parts.Count -ne 2) { return $false }
    try {
        $net = [System.Net.IPAddress]::Parse($parts[0]).GetAddressBytes()
        $ip  = [System.Net.IPAddress]::Parse($Ip).GetAddressBytes()
    } catch { return $false }
    $mask = [int]$parts[1]
    for ($i = 0; $i -lt 4; $i++) {
        $bits = [Math]::Min(8, [Math]::Max(0, $mask - $i * 8))
        $m = if ($bits -eq 8) { 0xFF } elseif ($bits -eq 0) { 0 } else { (0xFF -shl (8 - $bits)) -band 0xFF }
        if (($net[$i] -band $m) -ne ($ip[$i] -band $m)) { return $false }
    }
    return $true
}

function Find-Subnet ([string]$Ip, [array]$Subnets) {
    foreach ($s in $Subnets) {
        foreach ($cidr in @($s.addressPrefix) + @($s.addressPrefixes)) {
            if ($cidr -and (Test-IpInCidr $Ip $cidr)) {
                return @{ cidr = $cidr; subnet = $s.subnetName; vnet = $s.vnetName; rg = $s.resourceGroup }
            }
        }
    }
    return $null
}

function Add-ToList ([System.Collections.Generic.List[object]]$List, [object]$Item) {
    $List.Add($Item) | Out-Null
}

function Group-ByKey ([array]$Items, [string[]]$Keys) {
    $map = @{}
    foreach ($item in $Items) {
        $k = ($Keys | ForEach-Object { $item.$_ }) -join '|'
        if ($map.ContainsKey($k)) { $map[$k].totalBytes += [long]$item.totalBytes }
        else { $map[$k] = $item.PSObject.Copy() }
    }
    @($map.Values | Sort-Object totalBytes -Descending)
}

function Add-ClassifiedFlow ([string]$SrcIp, [string]$DestIp, [string]$Port,
        [string]$Protocol, [long]$TotalBytes, [string]$TrafficClass,
        [System.Collections.Generic.List[object]]$FwList,
        [System.Collections.Generic.List[object]]$NsgList, [array]$SubnetList) {
    $src  = Find-Subnet $SrcIp $SubnetList
    $dest = Find-Subnet $DestIp $SubnetList

    if ($TrafficClass -eq 'EastWest' -and $src -and $dest) {
        if ($src.cidr -eq $dest.cidr) {
            # IntraSubnet → NSG (same subnet)
            Add-ToList $NsgList ([pscustomobject]@{
                vnet = $dest.vnet; subnet = $dest.subnet; cidr = $dest.cidr
                srcIp = $SrcIp; destIp = $DestIp
                port = $Port; protocol = $Protocol; totalBytes = $TotalBytes
                category = 'IntraSubnet'
            })
        }
        elseif ($src.vnet -eq $dest.vnet) {
            # InterSubnet → NSG (same VNet, different subnet, grouped by dest subnet)
            Add-ToList $NsgList ([pscustomobject]@{
                vnet = $dest.vnet; subnet = $dest.subnet; cidr = $dest.cidr
                srcIp = $SrcIp; destIp = $DestIp
                port = $Port; protocol = $Protocol; totalBytes = $TotalBytes
                category = 'InterSubnet'
            })
        }
        else {
            # InterVNet → Firewall (different VNets)
            Add-ToList $FwList ([pscustomobject]@{
                srcIp = $SrcIp; destIp = $DestIp
                port = $Port; protocol = $Protocol; totalBytes = $TotalBytes
                category = 'InterVNet'
            })
        }
    }
    elseif ($TrafficClass -eq 'EastWest') {
        # Both private but not in known subnets → InterVNet best-effort
        Add-ToList $FwList ([pscustomobject]@{
            srcIp = $SrcIp; destIp = $DestIp
            port = $Port; protocol = $Protocol; totalBytes = $TotalBytes
            category = 'InterVNet'
        })
    }
    else {
        # Egress or Ingress → Firewall
        Add-ToList $FwList ([pscustomobject]@{
            srcIp = $SrcIp; destIp = $DestIp
            port = $Port; protocol = $Protocol; totalBytes = $TotalBytes
            category = $TrafficClass
        })
    }
}

# ── Step 1: Query ────────────────────────────────────────────────────────────

Write-Host "`n── Step 1: Query traffic ($Lookback) ──"

$kql = @"
NTANetAnalytics
| where TimeGenerated > ago($Lookback)
| where isnotempty(SrcIp) and isnotempty(DestIp)
| summarize TotalBytes = sum(tolong(BytesSrcToDest)), TotalFlows = count()
    by SrcIp, DestIp, DestPort, L4Protocol, FlowDirection
| extend SrcIsPrivate = ipv4_is_private(SrcIp), DestIsPrivate = ipv4_is_private(DestIp)
| extend TrafficClass = case(
    SrcIsPrivate and DestIsPrivate, 'EastWest',
    SrcIsPrivate and not(DestIsPrivate), 'Egress',
    not(SrcIsPrivate) and DestIsPrivate, 'Ingress',
    'Unknown')
| extend IsHighPort = DestPort >= $HighPortThreshold
"@

$kqlPath = Join-Path $queryResults 'traffic.rendered.kql'
[IO.File]::WriteAllText($kqlPath, $kql, [Text.UTF8Encoding]::new($false))

Write-Host "  Querying $WorkspaceId ..."
$raw = az monitor log-analytics query --workspace $WorkspaceId --analytics-query "@$(Resolve-Path $kqlPath)" --output json 2>&1
if ($LASTEXITCODE -ne 0) { throw "Query failed:`n$($raw | Out-String)" }

$json = ($raw | Out-String).Trim()
$trafficPath = Join-Path $queryResults 'traffic.json'
[IO.File]::WriteAllText($trafficPath, $json, [Text.UTF8Encoding]::new($false))
$traffic = @($json | ConvertFrom-Json)
Write-Host "  $($traffic.Count) tuples"

# ── Step 2: Discover subnets ─────────────────────────────────────────────────

Write-Host "`n── Step 2: Discover subnets ──"

$vnetsRaw = az network vnet list --query '[].{name:name,resourceGroup:resourceGroup,subnets:subnets[].{name:name,addressPrefix:addressPrefix,addressPrefixes:addressPrefixes}}' --output json 2>&1
if ($LASTEXITCODE -ne 0) { throw "VNet list failed:`n$($vnetsRaw | Out-String)" }

$vnets = @(($vnetsRaw | Out-String).Trim() | ConvertFrom-Json)
$subnets = foreach ($v in $vnets) {
    foreach ($s in $v.subnets) {
        [pscustomobject]@{
            resourceGroup   = $v.resourceGroup
            vnetName        = $v.name
            subnetName      = $s.name
            addressPrefix   = $s.addressPrefix
            addressPrefixes = @($s.addressPrefixes | Where-Object { $_ })
        }
    }
}
$subnets = @($subnets)

$subnetPath = Join-Path $queryResults 'subnet-cidrs.json'
$subnets | ConvertTo-Json -Depth 5 | Set-Content $subnetPath -Encoding utf8NoBOM
Write-Host "  $($subnets.Count) subnets across $($vnets.Count) VNets"

# ── Step 3: Classify ─────────────────────────────────────────────────────────

Write-Host "`n── Step 3: Classify ──"

$fw      = [System.Collections.Generic.List[object]]::new()   # firewall rules (Egress, Ingress, InterVNet)
$nsg     = [System.Collections.Generic.List[object]]::new()   # NSG rules (IntraSubnet, InterSubnet)
$hiport  = [System.Collections.Generic.List[object]]::new()   # needs review

foreach ($f in $traffic) {
    $port = [string]$f.DestPort
    $proto = [string]$f.L4Protocol
    $bytes = [long]$f.TotalBytes
    $cls   = [string]$f.TrafficClass

    # Skip rows with no usable port (e.g. ICMP or null)
    $portNum = 0
    if (-not [int]::TryParse($port, [ref]$portNum)) { continue }

    # Park high-port flows for review
    if ($portNum -ge $HighPortThreshold) {
        Add-ToList $hiport ([pscustomobject]@{
            srcIp = $f.SrcIp; destIp = $f.DestIp; port = $port; protocol = $proto
            totalBytes = $bytes; trafficClass = $cls; direction = $f.FlowDirection
        })
        continue
    }

    Add-ClassifiedFlow -SrcIp $f.SrcIp -DestIp $f.DestIp -Port $port `
        -Protocol $proto -TotalBytes $bytes -TrafficClass $cls `
        -FwList $fw -NsgList $nsg -SubnetList $subnets
}

Write-Host "  Firewall: $($fw.Count) | NSG: $($nsg.Count) | High-port: $($hiport.Count)"

# ── Step 4: High-port review ─────────────────────────────────────────────────

Write-Host "`n── Step 4: High-port review ──"

$skipped = [System.Collections.Generic.List[object]]::new()

if ($hiport.Count -eq 0) {
    Write-Host '  None.'
}
elseif ($NonInteractive) {
    Write-Host "  Non-interactive: $($hiport.Count) flows excluded."
    $skipped.AddRange($hiport)
}
else {
    $groups = $hiport | Group-Object destIp |
        Sort-Object { ($_.Group | Measure-Object totalBytes -Sum).Sum } -Descending

    foreach ($g in $groups) {
        $ip     = $g.Name
        $flows  = $g.Group
        $ports  = ($flows.port | Sort-Object { [int]$_ } -Unique)
        $range  = "$($ports[0])-$($ports[-1])"
        $mb     = [math]::Round(($flows | Measure-Object totalBytes -Sum).Sum / 1MB, 2)

        Write-Host "`n  $ip  |  $($ports.Count) ports ($range)  |  $mb MB"
        Write-Host '  [A] Allow all ports  [R] Allow as range  [S] Skip (default)'
        $choice = (Read-Host '  Choice').Trim().ToUpper()
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = 'S' }

        switch ($choice[0]) {
            'A' {
                Write-Host "    -> $($ports.Count) individual rules"
                foreach ($fl in $flows) {
                    Add-ClassifiedFlow -SrcIp $fl.srcIp -DestIp $fl.destIp -Port $fl.port `
                        -Protocol $fl.protocol -TotalBytes $fl.totalBytes -TrafficClass $fl.trafficClass `
                        -FwList $fw -NsgList $nsg -SubnetList $subnets
                }
            }
            'R' {
                $srcGroups = $flows | Group-Object srcIp
                Write-Host "    -> $($srcGroups.Count) range rule(s) ($range)"
                foreach ($sg in $srcGroups) {
                    $sgFlows = $sg.Group
                    $rep = $sgFlows | Sort-Object totalBytes -Descending | Select-Object -First 1
                    $tb  = ($sgFlows | Measure-Object totalBytes -Sum).Sum
                    Add-ClassifiedFlow -SrcIp $sg.Name -DestIp $ip -Port $range `
                        -Protocol $rep.protocol -TotalBytes $tb -TrafficClass $rep.trafficClass `
                        -FwList $fw -NsgList $nsg -SubnetList $subnets
                }
            }
            default {
                Write-Host "    -> Skipped"
                $skipped.AddRange($flows)
            }
        }
    }
}

if ($skipped.Count -gt 0) {
    $skipPath = Join-Path $OutputFolder 'high-port-skipped.json'
    $skipped | ConvertTo-Json -Depth 5 | Set-Content $skipPath -Encoding utf8NoBOM
    Write-Host "  Skipped flows: $skipPath"
}

# ── Step 5: Deduplicate and write JSON ────────────────────────────────────────

Write-Host "`n── Step 5: Write JSON ──"

$fwGrouped  = @(Group-ByKey $fw  @('srcIp','destIp','port','protocol','category'))
$nsgGrouped = @(Group-ByKey $nsg @('vnet','subnet','cidr','srcIp','destIp','port','protocol','category'))

# firewall-rules.json — IP-level rules
$fwJson = [pscustomobject]@{
    metadata = [pscustomobject]@{
        workspace = $WorkspaceId
        lookback  = $Lookback
        generated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        location  = $Location
    }
    rules = @($fwGrouped | ForEach-Object {
        [pscustomobject]@{
            srcIp       = $_.srcIp
            destIp      = $_.destIp
            port        = [string]$_.port
            protocol    = $_.protocol
            category    = $_.category
            totalBytes  = $_.totalBytes
        }
    })
}

$fwPath = Join-Path $OutputFolder 'firewall-rules.json'
$fwJson | ConvertTo-Json -Depth 5 | Set-Content $fwPath -Encoding utf8NoBOM

# nsg-rules.json — grouped by destination subnet, IP-level rules
$nsgBySubnet = @{}
foreach ($r in $nsgGrouped) {
    $key = "$($r.vnet)/$($r.subnet)"
    if (-not $nsgBySubnet.ContainsKey($key)) {
        $nsgBySubnet[$key] = [pscustomobject]@{
            vnet = $r.vnet; subnet = $r.subnet; cidr = $r.cidr; rules = [System.Collections.Generic.List[object]]::new()
        }
    }
    $nsgBySubnet[$key].rules.Add([pscustomobject]@{
        srcIp = $r.srcIp; destIp = $r.destIp
        port = [string]$r.port; protocol = $r.protocol; category = $r.category; totalBytes = $r.totalBytes
    })
}

$nsgJson = [pscustomobject]@{
    metadata = [pscustomobject]@{
        workspace = $WorkspaceId
        lookback  = $Lookback
        generated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        location  = $Location
    }
    subnets = @($nsgBySubnet.Values | Sort-Object vnet, subnet)
}

$nsgPath = Join-Path $OutputFolder 'nsg-rules.json'
$nsgJson | ConvertTo-Json -Depth 5 | Set-Content $nsgPath -Encoding utf8NoBOM

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Host "`n══ Done ══════════════════════════════════════════════════"
Write-Host "  Output:             $OutputFolder"
Write-Host "  Firewall rules:     $($fwGrouped.Count)"
Write-Host "  NSG subnet groups:  $($nsgBySubnet.Count)"
Write-Host "  High-port skipped:  $($skipped.Count)"
Write-Host ''
Write-Host '  Deploy firewall rules:'
Write-Host "    az deployment group create -g <rg> -f infra/modules/firewall-observed-rules.bicep -p rulesFile=$fwPath"
Write-Host '  Deploy NSG rules:'
Write-Host "    az deployment group create -g <rg> -f infra/modules/nsg-observed-rules.bicep -p rulesFile=$nsgPath"
