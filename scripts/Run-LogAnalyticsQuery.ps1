[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $true)]
    [string]$QueryFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [string]$RenderedQueryFile,

    [string[]]$Replace = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $QueryFile -PathType Leaf)) {
    throw "Query file not found: $QueryFile"
}

$queryText = Get-Content -LiteralPath $QueryFile -Raw

foreach ($replacement in $Replace) {
    $separator = if ($replacement.Contains('=>')) { '=>' } else { '=' }
    $parts = $replacement -split [regex]::Escape($separator), 2
    if ($parts.Count -ne 2) {
        throw "Invalid replacement '$replacement'. Use <token>=<value> or <token>=> <value>."
    }

    $queryText = $queryText.Replace($parts[0], $parts[1])
}

$queryText = (($queryText -split "`r?`n") | Where-Object { $_ -notmatch '^\s*//' }) -join [Environment]::NewLine
$queryText = $queryText.Trim()

if ([string]::IsNullOrWhiteSpace($queryText)) {
    throw "Rendered query is empty after replacements and comment cleanup: $QueryFile"
}

$outputDirectory = Split-Path -Parent $OutputFile
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($RenderedQueryFile)) {
    $outputBaseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputFile)
    $RenderedQueryFile = Join-Path -Path $outputDirectory -ChildPath ($outputBaseName + '.rendered.kql')
}

$renderedQueryDirectory = Split-Path -Parent $RenderedQueryFile
if (-not [string]::IsNullOrWhiteSpace($renderedQueryDirectory)) {
    New-Item -ItemType Directory -Path $renderedQueryDirectory -Force | Out-Null
}

[System.IO.File]::WriteAllText($RenderedQueryFile, $queryText, [System.Text.UTF8Encoding]::new($false))

$resolvedRenderedQueryFile = (Resolve-Path -LiteralPath $RenderedQueryFile).Path
$queryResult = az monitor log-analytics query --workspace $WorkspaceId --analytics-query "@$resolvedRenderedQueryFile" --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    $errorText = ($queryResult | Out-String).Trim()
    throw "Azure CLI query failed. Rendered query: $RenderedQueryFile`n$errorText"
}

$resultText = ($queryResult | Out-String).Trim()
[System.IO.File]::WriteAllText($OutputFile, $resultText, [System.Text.UTF8Encoding]::new($false))

Write-Host "Rendered query written to $RenderedQueryFile"
Write-Host "Query results written to $OutputFile"