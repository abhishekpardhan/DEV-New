param(
    [Parameter(Mandatory = $true)]
    [string]$SourceQueryFile,

    [Parameter(Mandatory = $true)]
    [string[]]$ChunkFiles,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [string]$IdsOutputFile
)

$sourceText = Get-Content -LiteralPath $SourceQueryFile -Raw
$excludedIds = [regex]::Matches($sourceText, "'(?<id>005[A-Za-z0-9]{15})'") |
    ForEach-Object { $_.Groups['id'].Value } |
    Sort-Object -Unique
$excluded = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]$excludedIds,
    [System.StringComparer]::OrdinalIgnoreCase
)

$resolvedChunkFiles = $ChunkFiles | ForEach-Object { $_ -split ',' }

$records = foreach ($chunkFile in $resolvedChunkFiles) {
    Import-Csv -LiteralPath $chunkFile
}

$result = $records |
    Where-Object { -not $excluded.Contains($_.Id) } |
    Sort-Object Name, Id

$outputDirectory = Split-Path -Parent $OutputFile
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$result | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding utf8

if ($IdsOutputFile) {
    $idsOutputDirectory = Split-Path -Parent $IdsOutputFile
    if ($idsOutputDirectory) {
        New-Item -ItemType Directory -Path $idsOutputDirectory -Force | Out-Null
    }
    $result.Id | Set-Content -LiteralPath $IdsOutputFile -Encoding utf8
}

[pscustomobject]@{
    ExcludedIds = $excluded.Count
    QueriedUsers = $records.Count
    ResultUsers = $result.Count
    OutputFile = (Resolve-Path -LiteralPath $OutputFile).Path
    IdsOutputFile = if ($IdsOutputFile) { (Resolve-Path -LiteralPath $IdsOutputFile).Path } else { $null }
} | ConvertTo-Json
