$ErrorActionPreference='Stop'
$out=$PSScriptRoot
$review=(Resolve-Path "$out/..").Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$d=(Get-Content "$out/deployment-report.json" -Raw | ConvertFrom-Json).result
$org=(Get-Content "$out/org.json" -Raw | ConvertFrom-Json).result.records[0]
$groups=@((Get-Content "$out/groups.json" -Raw | ConvertFrom-Json).result.records)
$owd=(Get-Content "$out/lead-owd.json" -Raw | ConvertFrom-Json).result.records[0]
[xml]$manifest=Get-Content "$review/deployment-payload/package.xml"
$successes=@($d.details.componentSuccesses | Where-Object componentType)
$rows=@()
foreach($type in $manifest.Package.types){foreach($name in $type.members){
    $match=@($successes | Where-Object {$_.componentType -ceq $type.name -and $_.fullName -ceq $name})
    if($match.Count -ne 1){throw "Manifest/report mismatch: $($type.name):$name"}
    $entry=$match[0]
    $relative=([string]$entry.fileName) -replace '^zip/',''
    $file=Join-Path "$review/deployment-payload" $relative
    if(!(Test-Path -LiteralPath $file)){throw "Missing payload file: $file"}
    $rows += [pscustomobject]@{MetadataType=[string]$type.name;ComponentAPIName=[string]$name;ManifestPath="$review/deployment-payload/package.xml";PayloadFile=(Resolve-Path $file).Path;DeploymentJobId=$d.id;JobStatus=$d.status;CheckOnly=$d.checkOnly;Result=$(if($d.checkOnly){'VALIDATED ONLY - NOT APPLIED BY THIS JOB'}else{'See deployment result'});CurrentLiveEvidence=$(if($type.name -eq 'Group'){if([string]$name -cin @($groups.DeveloperName)){'Group exists in live query'}else{'Group absent in live query'}}elseif($type.name -eq 'CustomObject'){"Internal=$($owd.InternalSharingModel); External=$($owd.ExternalSharingModel)"}else{'Rule metadata not retrieved; job did not apply this rule'})}
}}
if($rows.Count -ne 54 -or !$d.checkOnly -or !$d.success){throw 'Unexpected result; review manually'}
$rows | Export-Csv "$out/all-package-components.csv" -NoTypeInformation
$text=@('# All components named in package.xml','','The manifest contains 54 components in 21 definition files, plus package.xml. The 34 rules share one Lead.sharingRules file. All 54 were validated by the reported job; none was applied by that check-only job.','','| Metadata type | Component API name | Full payload file | Job result | Current live evidence |','| --- | --- | --- | --- | --- |')
foreach($r in $rows){$text+="| $($r.MetadataType) | $($r.ComponentAPIName) | $($r.PayloadFile) | $($r.Result) | $($r.CurrentLiveEvidence) |"}
[IO.File]::WriteAllText("$out/all-package-components.md",($text -join "`r`n"),$utf8)
$payloadFiles=@(Get-ChildItem "$review/deployment-payload" -Recurse -File | ForEach-Object {[pscustomobject]@{File=$_.FullName;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash;Purpose=$(if($_.Name -eq 'package.xml'){'Manifest'}else{'Metadata definition'});Status='Validated only; not applied by reported job'}})
$payloadFiles | Export-Csv "$out/all-package-files.csv" -NoTypeInformation
$report=@(
'# Dev1 live verification - requirements are NOT complete','',
"Verified org: $($org.Name); alias Dev1; org ID $($org.Id); sandbox=$($org.IsSandbox).",
"Latest deployment job: $($d.id); status=$($d.status); success=$($d.success); checkOnly=$($d.checkOnly); component errors=$($d.numberComponentErrors).",
"Job completed at $($d.completedDate) (2026-10-21 17:26:59 Asia/Calcutta). This is validation, not an actual deployment.",'',
'The numberComponentsDeployed field reports 54 in this API result, but checkOnly=true means those components were validated without being saved. Per-component created/changed flags likewise describe the validation result, not committed changes.','',
'| Requirement | Expected | Current evidence | Done? |',
'| --- | --- | --- | --- |',
'| C-02 app navigation | standard-Lead in safexpress2_0 | Previously verified in local XML; not queried live in this check | Local yes; live unverified |',
"| C-03 Lead internal OWD | Private | $($owd.InternalSharingModel) from live EntityDefinition | NO |",
"| C-03 Lead external OWD | Private | $($owd.ExternalSharingModel) from live EntityDefinition | NO |",
'| C-04 regional groups | 18 groups | None of the exact proposed names exists in live Group query | NO |',
'| C-04 regional memberships | 4 direct Roles per group / 72 total | Parent public groups absent | NO |',
'| C-05 Safexperience group | Group exists, initially empty, hierarchy enabled | Exact group name absent in live query | NO |',
'| C-06 sharing rules | 18 regional + 14 VH + 1 Alliance + 1 Safexperience | All 34 passed this job without file-level errors, but check-only saved none; rule metadata not retrieved | Not applied by this job; full model incomplete |',
'| Existing VH/Alliance groups | Reuse 14 VH groups and Alliance | All 15 definitions exist live with DoesIncludeBosses=true; members not queried | Definitions yes; membership unverified |',
'| Role identities/hierarchy | Exact 72 roles; retain approved GJT hierarchy | Local role evidence only in this check | Live verification outstanding |',
'| UST1 / UST4 / UST8 / Dev 5 | Dependencies and persona access accepted | No new acceptance evidence | Outstanding |',
'| Visibility testing | Positive/negative access matrix after recalculation | No runtime tests performed | Outstanding |','',
'## All XML contents',
'all-package-components.md/csv lists each of the 54 manifest members and its exact full payload file path. all-package-files.csv lists all 22 physical files, including package.xml. No field, validation rule, profile, permission set, Apex, Flow, role or app component is in the isolated package.','',
'## Next steps',
'1. Use the reviewed group-only deployment command (without --dry-run) when ready to perform the actual approved deployment.',
'2. Add and verify the four direct Role members in each regional group using membership-setup-checklist.csv. Keep hierarchy access enabled and Safexperience initially empty; review unexpected existing members rather than deleting them.',
'3. Validate and then actually deploy access-payload for Lead OWD and all 34 rules. The actual deployment command omits --dry-run. See ../dev-deployment-plan.md for the exact phase commands.',
'4. Confirm an actual job has success=true AND checkOnly=false, verify OWD/groups/rules in the org, wait for recalculation and run persona access tests.',
'5. Confirm external-team dependencies and repeat QA-specific checks before promotion.','',
'Only read-only deployment-report and SOQL queries were run for this audit. No metadata retrieval, deployment, validation job, data mutation or Setup update was executed. The live checks establish the current absence of the proposed groups and unchanged OWD; they do not claim that every unrelated previous org operation was inspected.'
)
[IO.File]::WriteAllText("$out/completion-verdict.md",($report -join "`r`n"),$utf8)
$records=@(Import-Csv "$review/deployment-record.csv")
if(@($records | Where-Object {$_.ActualDeploymentId -ceq $d.id -and $_.Step -eq 'Validate complete 54-component package'}).Count -eq 0){
    $records += [pscustomobject]@{Environment='DEV';Step='Validate complete 54-component package';Status='SUCCEEDED - CHECK ONLY; NOT DEPLOYED';ActualOrgId=$org.Id;ActualDeploymentId=$d.id;PerformedAt=$d.completedDate;ArtifactSHA256='';EvidencePath="$out/deployment-report.json";Notes='Existing user-run job verified read-only; no actual deployment performed by this audit. Local hashes are recorded separately; server does not attest a ZIP checksum.'}
    $records | Export-Csv "$review/deployment-record.csv" -NoTypeInformation
}
"Manifest/report match: $($rows.Count) components; $($payloadFiles.Count) physical files. Verdict: not complete, check-only job."
