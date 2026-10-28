$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead('C:\Users\80629\Downloads\final Sheet for roles assighment.xlsx')
function Read-ZipXml([string]$Path) {
    $reader = [IO.StreamReader]::new($zip.GetEntry($Path).Open())
    try { return [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
}
try {
    $stringsXml = Read-ZipXml 'xl/sharedStrings.xml'
    $strings = @($stringsXml.DocumentElement.ChildNodes | ForEach-Object { $_.InnerText })
    $sheet = Read-ZipXml 'xl/worksheets/sheet1.xml'
    $rows = @(foreach ($row in $sheet.worksheet.sheetData.row) {
        if ([int]$row.r -eq 1) { continue }
        $values = @{}
        foreach ($cell in $row.c) {
            $column = $cell.r -replace '\d', ''
            $value = [string]$cell.v
            if ($cell.t -eq 's' -and $value -ne '') { $value = $strings[[int]$value] }
            elseif ($cell.t -eq 'inlineStr') { $value = $cell.is.InnerText }
            $values[$column] = $value
        }
        if ($values['A'] -or $values['B'] -or $values['C']) {
            [pscustomobject]@{Sheet='Sheet1'; Row=[int]$row.r; UserName=[string]$values['A']; CurrentRole=[string]$values['B']; TargetRole=[string]$values['C']}
        }
    })
    $rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$PSScriptRoot\workbook-rows.json" -Encoding UTF8
    $rows | Export-Csv -LiteralPath "$PSScriptRoot\workbook-rows.csv" -NoTypeInformation -Encoding UTF8
    Write-Output "Workbook rows: $($rows.Count)"
    Write-Output "Blank target roles: $(@($rows | Where-Object { -not $_.TargetRole }).Count)"
    $rows | Select-Object -First 8 | Format-Table -AutoSize
} finally { $zip.Dispose() }
