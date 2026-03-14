[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequestFolder,

    [string]$PerVnetResultsRoot,

    [string]$OutputFile,

    [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PlaceholderTokens {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VnetName,

        [Parameter(Mandatory = $true)]
        [string]$SubnetName
    )

    $vnetAlias = $VnetName.ToLowerInvariant()
    if ($vnetAlias.StartsWith('vnet-')) {
        $vnetAlias = $vnetAlias.Substring(5)
    }
    if ($vnetAlias.EndsWith('-vnet')) {
        $vnetAlias = $vnetAlias.Substring(0, $vnetAlias.Length - 5)
    }

    $subnetAlias = $SubnetName.ToLowerInvariant()
    $tokens = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($subnetAlias -eq 'gatewaysubnet') {
        $null = $tokens.Add('replace-with-gatewaysubnet-cidr')
        $null = $tokens.Add("replace-with-$vnetAlias-gatewaysubnet-cidr")
    }
    elseif ($subnetAlias.Contains('subnet')) {
        $null = $tokens.Add("replace-with-$vnetAlias-$subnetAlias-cidr")
    }
    else {
        $null = $tokens.Add("replace-with-$vnetAlias-$subnetAlias-subnet-cidr")
        $null = $tokens.Add("replace-with-$vnetAlias-$subnetAlias-cidr")
    }

    return @($tokens | Sort-Object)
}

function Get-PlaceholderGroups {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VnetName,

        [Parameter(Mandatory = $true)]
        [string]$SubnetName
    )

    $groups = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if ($SubnetName -ne 'default') {
        return @()
    }

    $vnetAlias = $VnetName.ToLowerInvariant()
    if ($vnetAlias.StartsWith('vnet-')) {
        $vnetAlias = $vnetAlias.Substring(5)
    }
    if ($vnetAlias.EndsWith('-vnet')) {
        $vnetAlias = $vnetAlias.Substring(0, $vnetAlias.Length - 5)
    }

    $match = [regex]::Match($vnetAlias, '^(?<group>[a-z-]+)\d+$')
    if ($match.Success) {
        $null = $groups.Add($match.Groups['group'].Value)
    }

    return @($groups | Sort-Object)
}

function Get-ActiveSubscriptionId {
    $activeSubscriptionId = az account show --query id --output tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($activeSubscriptionId)) {
        throw 'Unable to resolve the active Azure subscription ID from Azure CLI.'
    }

    return $activeSubscriptionId.Trim()
}

if (-not (Test-Path -LiteralPath $RequestFolder -PathType Container)) {
    throw "Request folder not found: $RequestFolder"
}

if ([string]::IsNullOrWhiteSpace($PerVnetResultsRoot)) {
    $PerVnetResultsRoot = Join-Path -Path $RequestFolder -ChildPath 'query-results\per-vnet'
}

if (-not (Test-Path -LiteralPath $PerVnetResultsRoot -PathType Container)) {
    throw "Per-VNet results folder not found: $PerVnetResultsRoot"
}

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path -Path $RequestFolder -ChildPath 'query-results\subnet-cidrs.json'
}

$jsonFiles = Get-ChildItem -LiteralPath $PerVnetResultsRoot -Recurse -File -Filter '*.json'
if (-not $jsonFiles) {
    throw "No per-VNet JSON files found under: $PerVnetResultsRoot"
}

$subnetKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$subnetsToResolve = [System.Collections.Generic.List[object]]::new()
$subscriptionCandidates = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($jsonFile in $jsonFiles) {
    $content = Get-Content -LiteralPath $jsonFile.FullName -Raw

    foreach ($match in [regex]::Matches($content, '"TargetResourceId"\s*:\s*"(?<value>[^"]+)"')) {
        $targetResourceId = $match.Groups['value'].Value
        $subscriptionMatch = [regex]::Match($targetResourceId, '^(?<subscription>[0-9a-fA-F-]{36})/')
        if ($subscriptionMatch.Success) {
            $null = $subscriptionCandidates.Add($subscriptionMatch.Groups['subscription'].Value)
        }
    }

    foreach ($propertyName in @('SrcSubnet', 'DestSubnet')) {
        $propertyPattern = '"' + [regex]::Escape($propertyName) + '"\s*:\s*"(?<value>[^"]+)"'
        foreach ($match in [regex]::Matches($content, $propertyPattern)) {
            $subnetPath = $match.Groups['value'].Value.Trim()
            if ([string]::IsNullOrWhiteSpace($subnetPath)) {
                continue
            }

            $subnetMatch = [regex]::Match($subnetPath, '^(?<resourceGroup>[^/]+)/(?<vnetName>[^/]+)/(?<subnetName>[^/]+)$')
            if (-not $subnetMatch.Success) {
                continue
            }

            $subnetKey = ($subnetMatch.Groups['resourceGroup'].Value + '|' + $subnetMatch.Groups['vnetName'].Value + '|' + $subnetMatch.Groups['subnetName'].Value).ToLowerInvariant()
            if (-not $subnetKeys.Add($subnetKey)) {
                continue
            }

            $subnetsToResolve.Add([pscustomobject]@{
                resourceGroup = $subnetMatch.Groups['resourceGroup'].Value
                vnetName = $subnetMatch.Groups['vnetName'].Value
                subnetName = $subnetMatch.Groups['subnetName'].Value
            }) | Out-Null
        }
    }
}

if (-not $subnetsToResolve.Count) {
    throw "No analyzed subnets were discovered in: $PerVnetResultsRoot"
}

if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
    if ($subscriptionCandidates.Count -eq 1) {
        $SubscriptionId = @($subscriptionCandidates)[0]
    }
    else {
        $SubscriptionId = Get-ActiveSubscriptionId
    }
}

$outputDirectory = Split-Path -Parent $OutputFile
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$results = [System.Collections.Generic.List[object]]::new()

foreach ($subnet in $subnetsToResolve | Sort-Object resourceGroup, vnetName, subnetName) {
    $placeholderTokens = Get-PlaceholderTokens -VnetName $subnet.vnetName -SubnetName $subnet.subnetName
    $placeholderGroups = Get-PlaceholderGroups -VnetName $subnet.vnetName -SubnetName $subnet.subnetName

    $queryResult = az network vnet subnet show --resource-group $subnet.resourceGroup --vnet-name $subnet.vnetName --name $subnet.subnetName --query '{subnetResourceId:id,addressPrefix:addressPrefix,addressPrefixes:addressPrefixes}' --output json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $resolvedSubnet = $queryResult | Out-String | ConvertFrom-Json
        $addressPrefixes = @($resolvedSubnet.addressPrefixes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $results.Add([pscustomobject]@{
            subscriptionId = $SubscriptionId
            resourceGroup = $subnet.resourceGroup
            vnetName = $subnet.vnetName
            subnetName = $subnet.subnetName
            subnetResourceId = $resolvedSubnet.subnetResourceId
            addressPrefix = $resolvedSubnet.addressPrefix
            addressPrefixes = @($addressPrefixes)
            source = 'AzureCLI'
            placeholderTokens = @($placeholderTokens)
            placeholderGroups = @($placeholderGroups)
        }) | Out-Null
        continue
    }

    $results.Add([pscustomobject]@{
        subscriptionId = $SubscriptionId
        resourceGroup = $subnet.resourceGroup
        vnetName = $subnet.vnetName
        subnetName = $subnet.subnetName
        subnetResourceId = $null
        addressPrefix = $null
        addressPrefixes = @()
        source = 'AzureCLI-Unresolved'
        placeholderTokens = @($placeholderTokens)
        placeholderGroups = @($placeholderGroups)
        error = ($queryResult | Out-String).Trim()
    }) | Out-Null

    Write-Warning "Unable to resolve subnet CIDR for $($subnet.resourceGroup)/$($subnet.vnetName)/$($subnet.subnetName)."
}

$json = $results | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($OutputFile, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "Subnet CIDR manifest written to $OutputFile"
Write-Host "Resolved $((@($results | Where-Object { $_.source -eq 'AzureCLI' })).Count) analyzed subnets from Azure resource inventory."