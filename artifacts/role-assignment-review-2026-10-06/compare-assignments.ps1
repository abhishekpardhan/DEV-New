$ErrorActionPreference = 'Stop'
$rows = Get-Content -Raw "$PSScriptRoot\workbook-rows.json" | ConvertFrom-Json
$userResult = Get-Content -Raw "$PSScriptRoot\live-users.json" | ConvertFrom-Json
$roleResult = Get-Content -Raw "$PSScriptRoot\live-roles.json" | ConvertFrom-Json
if ($userResult.status -ne 0 -or $roleResult.status -ne 0 -or -not $userResult.result.done -or -not $roleResult.result.done) { throw 'Incomplete live queries' }
$users = @($userResult.result.records)
$roles = @($roleResult.result.records)
function Normalize([string]$Value) { return ($Value.Trim() -replace '\s+', ' ').ToLowerInvariant() }
function Add-Index($Index, [string]$Key, $Value) {
    if ($Key) { if (-not $Index.ContainsKey($Key)) { $Index[$Key] = [Collections.Generic.List[object]]::new() }; $Index[$Key].Add($Value) }
}
$usersByName=@{}; $usersByCode=@{}; $rolesByName=@{}; $rolesById=@{}; $sheetByName=@{}
foreach ($u in $users) {
    Add-Index $usersByName (Normalize $u.Name) $u
    if ($u.Name -match '-\s*(\d+)\s*$') { Add-Index $usersByCode ($Matches[1].TrimStart('0')) $u }
    if ($u.EmployeeNumber) { Add-Index $usersByCode ([string]$u.EmployeeNumber).TrimStart('0') $u }
}
foreach ($r in $roles) { Add-Index $rolesByName (Normalize $r.Name) $r; $rolesById[$r.Id]=$r }
foreach ($row in $rows) { Add-Index $sheetByName (Normalize $row.UserName) $row }
$results = @(foreach ($row in $rows) {
    $notes=[Collections.Generic.List[string]]::new()
    $key=Normalize $row.UserName
    $userMatches=@($usersByName[$key] | Where-Object { $_ })
    $matchMethod='Exact name (case and whitespace normalized)'
    $candidates=@()
    if ($userMatches.Count -eq 0 -and $row.UserName -match '-\s*(\d+)\s*$') {
        $code=$Matches[1].TrimStart('0')
        $candidates=@($usersByCode[$code] | Sort-Object Id -Unique)
        $base=Normalize ($row.UserName -replace '-\s*\d+\s*$', '')
        $userMatches=@($candidates | Where-Object { (Normalize ($_.Name -replace '-\s*\d+\s*$', '')) -eq $base })
        $matchMethod='Same name and numeric suffix (leading zeros ignored)'
    }
    $u=$null
    if ($userMatches.Count -eq 1) { $u=$userMatches[0] }
    $targetKey=Normalize $row.TargetRole
    $targets=@($rolesByName[$targetKey] | Where-Object { $_ })
    $target=$null
    if ($targets.Count -eq 1) { $target=$targets[0] }
    $status=''; $action=''; $currentCheck='Not checked'
    if (-not $row.UserName) { $status='USER NAME BLANK'; $action='Supply the intended user identifier.' }
    elseif ($userMatches.Count -gt 1) { $status='USER AMBIGUOUS'; $action='Select the correct User Id; multiple live users have the same name.' }
    elseif (-not $u) { $status='USER NOT FOUND'; $action='Confirm the user identifier and target org; no safe user match.'; if ($candidates.Count) { $notes.Add('Numeric suffix candidates have a different name; they were not accepted automatically.') } }
    elseif (-not $targetKey) { $status='BLANK TARGET - REVIEW'; $action='Confirm whether blank means no role or no requested change.' }
    elseif ($targets.Count -eq 0) { $status='TARGET ROLE NOT FOUND'; $action='Confirm the target role label and org hierarchy before considering an assignment.' }
    elseif ($targets.Count -gt 1) { $status='TARGET ROLE AMBIGUOUS'; $action='Select the intended UserRole Id; the role name is duplicated.' }
    elseif ($u.UserRoleId -eq $target.Id) { $status='CORRECT'; $action='Live assignment matches the spreadsheet target.' }
    else { $status='ROLE MISMATCH'; $action='Review live role versus spreadsheet target; target role exists in DEV2.' }
    if ($u) {
        $liveName=[string]$u.UserRole.Name
        if ((Normalize $row.CurrentRole) -eq (Normalize $liveName)) { $currentCheck='Matches live role' }
        else { $currentCheck='Differs from live role'; $notes.Add('Spreadsheet Current Roles is stale or inconsistent with DEV2.') }
        if (-not $u.IsActive) { $notes.Add('User is inactive; review separately before any future assignment change.') }
        if ($matchMethod -ne 'Exact name (case and whitespace normalized)') { $notes.Add('Name matches only after ignoring leading zeros in numeric suffix.') }
    }
    if ($sheetByName[$key].Count -gt 1) {
        $notes.Add('User name appears on multiple spreadsheet rows: ' + (($sheetByName[$key] | ForEach-Object {$_.Row}) -join ', '))
        $distinct=@($sheetByName[$key] | ForEach-Object { Normalize $_.TargetRole } | Sort-Object -Unique)
        if ($distinct.Count -gt 1) { $notes.Add('CONFLICT: duplicate spreadsheet rows specify different target roles.') }
    }
    $liveRole=$null; $parent=$null; $targetParent=$null
    if ($u -and $u.UserRoleId) { $liveRole=$rolesById[$u.UserRoleId]; if ($liveRole.ParentRoleId) { $parent=$rolesById[$liveRole.ParentRoleId] } }
    if ($target -and $target.ParentRoleId) { $targetParent=$rolesById[$target.ParentRoleId] }
    [pscustomobject][ordered]@{
        Sheet=$row.Sheet; ExcelRow=$row.Row; SpreadsheetUser=$row.UserName; SpreadsheetCurrentRole=$row.CurrentRole; SpreadsheetTargetRole=$row.TargetRole
        Status=$status; UserId=[string]$u.Id; LiveUserName=[string]$u.Name; Username=[string]$u.Username; IsActive=$(if($u){[string]$u.IsActive}else{''})
        LiveRoleId=[string]$u.UserRoleId; LiveRoleName=[string]$u.UserRole.Name; LiveRoleDeveloperName=[string]$u.UserRole.DeveloperName; LiveParentRole=[string]$parent.Name
        TargetRoleId=[string]$target.Id; TargetRoleDeveloperName=[string]$target.DeveloperName; TargetParentRole=[string]$targetParent.Name
        CurrentRoleCheck=$currentCheck; MatchMethod=$(if($u){$matchMethod}else{''}); Action=$action; Notes=($notes -join ' ')
        CandidateUsers=(($candidates | ForEach-Object { "$($_.Id): $($_.Name)" }) -join '; ')
        AmbiguousUsers=(($userMatches | Where-Object { $userMatches.Count -gt 1 } | ForEach-Object { "$($_.Id): $($_.Name)" }) -join '; ')
    }
})
if ($results.Count -ne $rows.Count) { throw 'Report row count does not match source workbook' }
$results | Export-Csv "$PSScriptRoot\All_Assignments.csv" -NoTypeInformation -Encoding UTF8
$issues=@($results | Where-Object {$_.Status -ne 'CORRECT'})
$issues | Export-Csv "$PSScriptRoot\Assignments_To_Review.csv" -NoTypeInformation -Encoding UTF8
$summary=@($results | Group-Object Status | Sort-Object Name | ForEach-Object { [pscustomobject]@{Status=$_.Name; Rows=$_.Count} })
$missing=@($results | Where-Object {$_.Status -eq 'TARGET ROLE NOT FOUND'} | Group-Object SpreadsheetTargetRole | Sort-Object Name | ForEach-Object { [pscustomobject]@{TargetRole=$_.Name; Rows=$_.Count; ExcelRows=(($_.Group.ExcelRow) -join ', ')} })
$blank=@($results | Where-Object {$_.Status -eq 'BLANK TARGET - REVIEW'})
$stale=@($results | Where-Object {$_.CurrentRoleCheck -eq 'Differs from live role'})
$duplicates=@($results | Where-Object {$_.Notes -like '*multiple spreadsheet rows*'})
$mismatches=@($results | Where-Object {$_.Status -eq 'ROLE MISMATCH'})
$metadata=@(
    [pscustomobject]@{Item='Org'; Value='DEV2 - safeforce1--sfxdev2.sandbox.my.salesforce.com - 00DC40000057tmTMAQ'},
    [pscustomobject]@{Item='Source'; Value='final Sheet for roles assighment.xlsx / Sheet1; original workbook unchanged'},
    [pscustomobject]@{Item='Snapshot date'; Value='2026-10-06 Asia/Calcutta; live read-only API v68.0 queries'},
    [pscustomobject]@{Item='Completeness'; Value="$($rows.Count) spreadsheet rows; $($users.Count) live users; $($roles.Count) live roles; both queries done=true"},
    [pscustomobject]@{Item='Correctness basis'; Value='Target Roles is the proposed assignment. Matching it proves spreadsheet consistency, not independently approved business suitability.'},
    [pscustomobject]@{Item='Matching'; Value='Case/whitespace normalized full name first; same base name and numeric suffix ignoring leading zeros second. Different-name suffix candidates remain unverified.'},
    [pscustomobject]@{Item='Blank target'; Value='Unspecified intent; never treated as an instruction to clear a role.'},
    [pscustomobject]@{Item='Role lookup'; Value='Normalized role label; no guessed mapping to a differently named role. Missing roles can indicate a stale sheet or a different target hierarchy.'},
    [pscustomobject]@{Item='Access review'; Value='This report checks User.UserRoleId and parent roles only; it does not audit profile, permission sets, CRUD/FLS, or effective record access.'}
)

# Create a standard XLSX directly with Open XML; Excel installation is not required.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Escape-Xml([string]$Value) { return [Security.SecurityElement]::Escape($Value) }
function Column-Name([int]$Number) { $value=''; while($Number -gt 0) { $Number--; $value=[char](65+($Number%26))+$value; $Number=[int][Math]::Floor($Number/26) }; return $value }
function Write-Entry($Zip,[string]$Name,[string]$Content) {
    $entry=$Zip.CreateEntry($Name)
    $writer=[IO.StreamWriter]::new($entry.Open(),[Text.UTF8Encoding]::new($false))
    try { $writer.Write($Content) } finally { $writer.Dispose() }
}
$tabs=@(
    @{Name='Read Me'; Data=$metadata}, @{Name='Summary'; Data=$summary}, @{Name='Role Mismatches'; Data=$mismatches},
    @{Name='All Review Rows'; Data=$issues}, @{Name='Missing Target Roles'; Data=$missing}, @{Name='Blank Targets'; Data=$blank},
    @{Name='Stale Current Roles'; Data=$stale}, @{Name='Duplicate Sheet Users'; Data=$duplicates}, @{Name='All Assignments'; Data=$results}
)
$file=[IO.File]::Open("$PSScriptRoot\DEV2_Role_Assignment_Review.xlsx",[IO.FileMode]::Create)
$zip=[IO.Compression.ZipArchive]::new($file,[IO.Compression.ZipArchiveMode]::Create)
try {
    $contentTypes='<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    $workbook='<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
    $rels='<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    for($i=0;$i -lt $tabs.Count;$i++) {
        $n=$i+1; $tab=$tabs[$i]; $data=@($tab.Data); $headers=@()
        if($data.Count) { $headers=@($data[0].PSObject.Properties.Name) } else { $headers=@('No rows') }
        $contentTypes+="<Override PartName=`"/xl/worksheets/sheet$n.xml`" ContentType=`"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml`"/>"
        $workbook+="<sheet name=`"$(Escape-Xml $tab.Name)`" sheetId=`"$n`" r:id=`"rId$n`"/>"
        $rels+="<Relationship Id=`"rId$n`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet`" Target=`"worksheets/sheet$n.xml`"/>"
        $xml=[Text.StringBuilder]::new()
        [void]$xml.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols>')
        [void]$xml.Append("<col min=`"1`" max=`"$($headers.Count)`" width=`"30`" customWidth=`"1`"/></cols><sheetData>")
        for($j=0;$j -le $data.Count;$j++) {
            $excelRow=$j+1; [void]$xml.Append("<row r=`"$excelRow`">")
            for($k=0;$k -lt $headers.Count;$k++) {
                $v=if($j -eq 0){$headers[$k]}else{[string]$data[$j-1].($headers[$k])}
                $ref=(Column-Name ($k+1))+$excelRow
                [void]$xml.Append("<c r=`"$ref`" t=`"inlineStr`"><is><t xml:space=`"preserve`">$(Escape-Xml $v)</t></is></c>")
            }
            [void]$xml.Append('</row>')
        }
        [void]$xml.Append("</sheetData><autoFilter ref=`"A1:$(Column-Name $headers.Count)$($data.Count+1)`"/></worksheet>")
        Write-Entry $zip "xl/worksheets/sheet$n.xml" $xml.ToString()
    }
    Write-Entry $zip '[Content_Types].xml' ($contentTypes+'</Types>')
    Write-Entry $zip 'xl/workbook.xml' ($workbook+'</sheets></workbook>')
    Write-Entry $zip 'xl/_rels/workbook.xml.rels' ($rels+'</Relationships>')
    Write-Entry $zip '_rels/.rels' '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
} finally { $zip.Dispose(); $file.Dispose() }
$summary | Format-Table -AutoSize
Write-Output "Stale current roles: $($stale.Count); Duplicate sheet rows: $($duplicates.Count); Missing target labels: $($missing.Count)"
$mismatches | Select-Object -First 12 ExcelRow,SpreadsheetUser,LiveRoleName,SpreadsheetTargetRole | Format-Table -AutoSize

