[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DraftFile,

    [Parameter(Mandatory = $true)]
    [string]$SubnetCidrsFile,

    [string]$OutputFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $DraftFile -PathType Leaf)) {
    throw "Draft file not found: $DraftFile"
}

if (-not (Test-Path -LiteralPath $SubnetCidrsFile -PathType Leaf)) {
    throw "Subnet CIDR manifest not found: $SubnetCidrsFile"
}

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = $DraftFile
}

$manifest = Get-Content -LiteralPath $SubnetCidrsFile -Raw | ConvertFrom-Json
$replacementMap = @{}

foreach ($entry in @($manifest)) {
    if ($entry.source -ne 'AzureCLI') {
        continue
    }

    $prefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (-not [string]::IsNullOrWhiteSpace($entry.addressPrefix)) {
        $null = $prefixes.Add([string]$entry.addressPrefix)
    }

    foreach ($prefix in @($entry.addressPrefixes)) {
        if (-not [string]::IsNullOrWhiteSpace($prefix)) {
            $null = $prefixes.Add([string]$prefix)
        }
    }

    foreach ($token in @($entry.placeholderTokens)) {
        if (-not $replacementMap.ContainsKey($token)) {
            $replacementMap[$token] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }

        foreach ($prefix in $prefixes) {
            $null = $replacementMap[$token].Add($prefix)
        }
    }

    foreach ($group in @($entry.placeholderGroups)) {
        $groupToken = "replace-with-$group-subnet-cidrs"
        if (-not $replacementMap.ContainsKey($groupToken)) {
            $replacementMap[$groupToken] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }

        foreach ($prefix in $prefixes) {
            $null = $replacementMap[$groupToken].Add($prefix)
        }
    }
}

$draftText = Get-Content -LiteralPath $DraftFile -Raw
$placeholders = [regex]::Matches($draftText, 'replace-with-[a-z0-9-]+') |
    ForEach-Object { $_.Value } |
    Where-Object { $_ -match 'cidrs?$' } |
    Sort-Object -Unique

$unresolvedPlaceholders = [System.Collections.Generic.List[string]]::new()

foreach ($placeholder in $placeholders) {
    if (-not $replacementMap.ContainsKey($placeholder)) {
        $unresolvedPlaceholders.Add($placeholder) | Out-Null
        continue
    }

    $values = @($replacementMap[$placeholder] | Sort-Object)
    if (-not $values.Count) {
        $unresolvedPlaceholders.Add($placeholder) | Out-Null
        continue
    }

    if ($values.Count -eq 1) {
        $draftText = $draftText.Replace("'$placeholder'", "'$($values[0])'")
        continue
    }

    $linePattern = "(?m)^(?<indent>\s*)'" + [regex]::Escape($placeholder) + "'$"
    $draftText = [regex]::Replace(
        $draftText,
        $linePattern,
        {
            param($match)

            $indent = $match.Groups['indent'].Value
            return (($values | ForEach-Object { "$indent'$_'" }) -join [Environment]::NewLine)
        }
    )
}

$outputDirectory = Split-Path -Parent $OutputFile
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

[System.IO.File]::WriteAllText($OutputFile, $draftText, [System.Text.UTF8Encoding]::new($false))

if ($unresolvedPlaceholders.Count) {
    Write-Warning ('Unresolved subnet placeholders: ' + (($unresolvedPlaceholders | Sort-Object -Unique) -join ', '))
}

Write-Host "Firewall draft updated from subnet CIDR manifest: $OutputFile"