$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
$base="$root/force-app/main/default"
$out=$PSScriptRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
$checks=New-Object System.Collections.Generic.List[object]
function Check($name,$ok,$evidence){$checks.Add([pscustomobject]@{Check=$name;Result=$(if($ok){'PASS'}else{'FAIL'});Evidence=$evidence});if(!$ok){throw "$name : $evidence"}}
function Record($name,$status,$evidence){$checks.Add([pscustomobject]@{Check=$name;Result=$status;Evidence=$evidence})}
function Xml($p){$x=New-Object System.Xml.XmlDocument;$x.PreserveWhitespace=$true;$x.Load($p);return ,$x}
$hashes=Import-Csv "$out/baseline/source-hashes.csv"
$before=@{};foreach($h in $hashes){$before[$h.Path]=$h.Hash}
$changed=@();$added=@();$deleted=@()
foreach($p in Get-ChildItem "$root/force-app" -Recurse -File){if($before.ContainsKey($p.FullName)){if((Get-FileHash -LiteralPath $p.FullName -Algorithm SHA256).Hash -ne $before[$p.FullName]){$changed+=$p.FullName}}else{$added+=$p.FullName}}
foreach($h in $hashes){if(!(Test-Path -LiteralPath $h.Path)){$deleted+=$h.Path}}
$allowed=@((Resolve-Path "$base/objects/Lead/Lead.object-meta.xml").Path,(Resolve-Path "$base/sharingRules/Lead.sharingRules-meta.xml").Path)
Check 'Only two existing source files changed' ($changed.Count -eq 2 -and @($changed | Where-Object {$_ -notin $allowed}).Count -eq 0) ($changed -join '; ')
Check 'Exactly 19 new source files, all approved group definitions' ($added.Count -eq 19 -and @($added | Where-Object {$_ -notmatch '\\groups\\(SG_RGN_[A-Z]{3}_RM|Safexperience_Team)\.group-meta\.xml$'}).Count -eq 0) '18 regional definitions plus Safexperience'
Check 'No source file deleted' ($deleted.Count -eq 0) 'All 20,630 pre-existing source files remain'
$parsed=@();foreach($p in @($changed)+@($added)+@(Get-ChildItem "$out/deployment-payload","$out/access-payload" -Recurse -File | ForEach-Object FullName)+@(Get-ChildItem "$out/manifest/*.xml" | ForEach-Object FullName)){$x=Xml $p;Check "XML namespace: $([IO.Path]::GetFileName($p))" ($x.DocumentElement.NamespaceURI -ceq 'http://soap.sforce.com/2006/04/metadata') $p;$parsed+=$p}
Check 'XML well formed for all new/modified payload files' ($parsed.Count -eq 48) "$($parsed.Count) files parsed (source, both isolated payloads and manifests)"
$m=Xml "$out/manifest/lead-sharing-story.xml"
Check 'Manifest version and allowed types' ($m.Package.version -eq '67.0' -and @($m.Package.types | Where-Object {$_.name -notin @('Group','CustomObject','SharingCriteriaRule')}).Count -eq 0) 'API 67.0; Group, CustomObject, SharingCriteriaRule only'
$manifestKeys=@();foreach($t in $m.Package.types){foreach($member in $t.members){$manifestKeys+="$($t.name):$member"}}
Check 'Unique manifest components' ($manifestKeys.Count -eq 54 -and @($manifestKeys | Select-Object -Unique).Count -eq 54) '19 groups + 34 individual criteria rules + Lead OWD'
$groups=@($added | ForEach-Object {Xml $_})
foreach($g in $groups){Check 'Group uses supported definition elements' (@($g.Group.ChildNodes | Where-Object {$_.NodeType -eq 'Element' -and $_.LocalName -notin @('doesIncludeBosses','name')}).Count -eq 0 -and $g.Group.doesIncludeBosses -eq 'true') ([string]$g.Group.name)}
$memberRows=@(Import-Csv "$out/group-membership-review.csv")
Check '72 exact intended Role identities individually evidenced' ($memberRows.Count -eq 72 -and @($memberRows | Group-Object RegionCode).Count -eq 18 -and @($memberRows | Group-Object RegionCode | Where-Object Count -ne 4).Count -eq 0 -and @($memberRows | Where-Object MembershipType -cne 'Role').Count -eq 0) 'Not Roles and Subordinates; each source Role file exists'
foreach($row in $memberRows){$x=Xml $row.VerifiedSource;Check 'Membership role identity exact' ($x.Role.name -ceq "$($row.RoleType) $($row.RegionCode)" -and [IO.Path]::GetFileName($row.VerifiedSource) -ceq "$($row.RoleDeveloperName).role-meta.xml") $row.RoleDeveloperName}
Record 'Exactly four actual members per regional group' 'BLOCKED' 'Group Metadata API does not transport memberships. No assignments performed; CSV is review evidence only.'
Record 'Safexperience empty initial membership' 'PROPOSED / LIVE UNVERIFIED' 'Definition contains no assignments; existing live state cannot be inferred or cleared.'
$r=Xml "$base/sharingRules/Lead.sharingRules-meta.xml"
$rules=@($r.SharingRules.sharingCriteriaRules)
Check 'Prepared rule count' ($rules.Count -eq 34) '18 regional + 14 VH + 1 Alliance + 1 Safexperience'
Check 'Prepared rule names unique and valid' (@($rules.fullName | Select-Object -Unique).Count -eq 34 -and @($rules | Where-Object {$_.fullName -notmatch '^[A-Za-z][A-Za-z0-9_]*$' -or $_.fullName -match '__|_$'}).Count -eq 0) 'No collision with empty baseline'
$plan=Get-Content "$out/planned-rules.json" -Raw | ConvertFrom-Json
foreach($rule in $rules){$p=@($plan | Where-Object Name -ceq $rule.fullName);Check 'Rule matches approved plan and access' ($p.Count -eq 1 -and ($p[0].Status -eq 'VERIFIED' -or ($p[0].Status -like 'APPROVED LEGACY INACTIVE:*' -and $p[0].Source -ceq 'Lead__c')) -and $p[0].Access -ceq $rule.accessLevel -and $p[0].Group -ceq $rule.sharedTo.group) $rule.fullName
    $c=@($rule.criteriaItems);Check 'Criteria cardinality exact' ($c.Count -eq $p[0].Conditions.Count) $rule.fullName
    for($i=0;$i -lt $c.Count;$i++){Check 'Criteria exact field/operator/value' ([string]$c[$i].field -ceq $p[0].Conditions[$i].field -and [string]$c[$i].operation -ceq $p[0].Conditions[$i].operation -and [string]$c[$i].value -ceq $p[0].Conditions[$i].value) $rule.fullName}
    Check 'No Type criterion' (@($c | Where-Object field -eq Type__c).Count -eq 0) $rule.fullName
    Check 'Target group definition exists' (Test-Path "$base/groups/$($rule.sharedTo.group).group-meta.xml") $rule.sharedTo.group
    Check 'Owner population scope retained' ([string]$rule.includeRecordsOwnedByAll -ceq 'false') $rule.fullName
    if($c.Count -gt 1){Check 'Boolean filter exact' ([string]$rule.booleanFilter -ceq $p[0].Logic) $rule.fullName}
}
Check 'Exactly 18 regional rules' (@($rules | Where-Object fullName -like 'SR_Lead_RGN_*').Count -eq 18) 'All 18 approved region values included'
Check 'Exactly 14 VH rules' (@($rules | Where-Object fullName -like 'SR_Lead_VH_*').Count -eq 14) '12 inactive-value rules explicitly approved by user'
Check 'Exactly one Alliance Read rule' (@($rules | Where-Object {$_.fullName -ceq 'SR_Lead_Alliance_Partner' -and $_.accessLevel -ceq 'Read'}).Count -eq 1) 'Exact verified Vertical value and existing group'
$saf=@($rules | Where-Object fullName -ceq 'SR_Lead_Safexperience_Team')
Check 'Exactly one Safexperience OR rule' ($saf.Count -eq 1 -and $saf[0].accessLevel -ceq 'Edit' -and $saf[0].booleanFilter -ceq '1 OR 2' -and @($saf[0].criteriaItems).Count -eq 2 -and $saf[0].criteriaItems[0].value -ceq 'Website' -and $saf[0].criteriaItems[1].value -ceq 'Safexperience Centre') 'Website OR Safexperience Centre, as confirmed'
Check '34 planned rules / all conditions represented' ($plan.Count -eq 34 -and @(Import-Csv "$out/sharing-rule-review.csv").Count -eq 41) 'CSV carries complete Boolean logic on each condition row'
$original=[IO.File]::ReadAllText("$out/baseline/Lead.object-meta.xml")
$expected=$original.Replace('<sharingModel>ReadWriteTransfer</sharingModel>','<sharingModel>Private</sharingModel>').Replace('<externalSharingModel>ReadWriteTransfer</externalSharingModel>','<externalSharingModel>Private</externalSharingModel>')
Check 'Only two OWD values changed; original formatting retained' ([IO.File]::ReadAllText("$base/objects/Lead/Lead.object-meta.xml") -ceq $expected) 'Byte-equivalent text except the two authorized value replacements'
$obj=Xml "$out/deployment-payload/objects/Lead.object"
Check 'Isolated object payload contains only Lead OWD' (@($obj.CustomObject.ChildNodes | Where-Object NodeType -eq Element).Count -eq 2 -and $obj.CustomObject.sharingModel -eq 'Private' -and $obj.CustomObject.externalSharingModel -eq 'Private') 'No child fields, action overrides, layouts or other object settings'
$payloadRules=Xml "$out/deployment-payload/sharingRules/Lead.sharingRules"
Check 'Source and isolated rule payload identical' ($payloadRules.OuterXml -ceq $r.OuterXml) '34 exact same rules'
Check 'Phase-two rule payload identical' ((Xml "$out/access-payload/sharingRules/Lead.sharingRules").OuterXml -ceq $r.OuterXml) 'Same 34 definitions'
Check 'Phase-two OWD payload identical' ((Xml "$out/access-payload/objects/Lead.object").OuterXml -ceq $obj.OuterXml) 'Only two sharing-model settings'
$gm=Xml "$out/manifest/lead-sharing-groups.xml"
Check 'Group-only phase has exactly 19 groups' (@($gm.Package.types).Count -eq 1 -and $gm.Package.types.name -ceq 'Group' -and @($gm.Package.types.members).Count -eq 19 -and $gm.Package.version -ceq '67.0') 'No OWD or rules in phase one'
$am=Xml "$out/access-payload/package.xml"
Check 'Access-only phase has exactly OWD and 34 rules' (@($am.Package.types).Count -eq 2 -and @($am.Package.types | Where-Object name -eq Group).Count -eq 0 -and @($am.Package.types | ForEach-Object {$_.members}).Count -eq 35 -and $am.Package.version -ceq '67.0') 'No groups or unrelated metadata in phase two'
$prior=Xml "$out/baseline/pre-confirmation-Lead.sharingRules-meta.xml"
foreach($old in $prior.SharingRules.sharingCriteriaRules){$now=@($rules | Where-Object fullName -ceq $old.fullName);Check 'Original 18 draft rules preserved exactly' ($now.Count -eq 1 -and $now[0].OuterXml -ceq $old.OuterXml) $old.fullName}
$legacy=Xml "$base/sharingRules/Lead__c.sharingRules-meta.xml"
foreach($new in @($rules | Where-Object fullName -like 'SR_Lead_VH_*')){
    $old=@($legacy.SharingRules.sharingCriteriaRules | Where-Object fullName -ceq $new.fullName.Substring(8))
    Check 'VH source rule exists exactly' ($old.Count -eq 1) $new.fullName
    Check 'VH target, access and owner scope unchanged' ($old[0].sharedTo.group -ceq $new.sharedTo.group -and $old[0].accessLevel -ceq $new.accessLevel -and $old[0].includeRecordsOwnedByAll -ceq $new.includeRecordsOwnedByAll) $new.fullName
    $oc=@($old[0].criteriaItems);$nc=@($new.criteriaItems)
    Check 'VH condition count unchanged' ($oc.Count -eq $nc.Count) $new.fullName
    for($i=0;$i -lt $oc.Count;$i++){Check 'VH exact legacy condition preserved' ([string]$oc[$i].field -ceq [string]$nc[$i].field -and [string]$oc[$i].operation -ceq [string]$nc[$i].operation -and [string]$oc[$i].value -ceq [string]$nc[$i].value) $new.fullName}
    $logic=if($old[0].booleanFilter){[string]$old[0].booleanFilter}else{(1..$oc.Count) -join ' AND '}
    if($oc.Count -gt 1){Check 'VH legacy Boolean semantics preserved' ($new.booleanFilter -ceq $logic) $new.fullName}
}
$sets=@{};foreach($pair in @(@('Region__c','Region'),@('Vertical__c','Vertical_Global'),@('Sub_Vertical__c','Sub_Vertical'))){$sets[$pair[0]]=@((Xml "$base/globalValueSets/$($pair[1]).globalValueSet-meta.xml").GlobalValueSet.customValue)}
$sets['LeadSource']=@((Xml "$base/standardValueSets/LeadSource.standardValueSet-meta.xml").StandardValueSet.standardValue)
foreach($rule in $rules){foreach($c in $rule.criteriaItems){$v=@($sets[[string]$c.field] | Where-Object {[string]$_.fullName -ceq [string]$c.value});Check 'Exact criterion value exists in standard Lead value set' ($v.Count -eq 1) "$($rule.fullName): $($c.value)";if($v[0].isActive -eq 'false'){Check 'Inactive criterion limited to approved legacy VH rules' ($rule.fullName -like 'SR_Lead_VH_*') $rule.fullName}}}
Record 'Inactive VH criteria behavior' 'USER APPROVED / ORG UNVERIFIED' 'Values retained exactly without reactivation or mapping; Salesforce deployment acceptance and runtime matching not tested'
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach($package in @(@('lead-sharing-metadata.zip','deployment-payload',22),@('lead-sharing-access.zip','access-payload',3))){
    $zip=[IO.Compression.ZipFile]::OpenRead("$out/$($package[0])")
    try{
        $entries=@($zip.Entries | Where-Object {$_.Name})
        Check 'ZIP has package.xml at root and exact file count' (@($entries | Where-Object FullName -ceq 'package.xml').Count -eq 1 -and $entries.Count -eq $package[2]) $package[0]
        foreach($entry in $entries){$stream=$entry.Open();$reader=New-Object IO.StreamReader($stream);try{$content=$reader.ReadToEnd()}finally{$reader.Dispose()};$path="$out/$($package[1])/$($entry.FullName)";Check 'ZIP entry matches reviewed XML' ((Test-Path -LiteralPath $path) -and $content -ceq [IO.File]::ReadAllText($path)) "$($package[0]):$($entry.FullName)"}
    }finally{$zip.Dispose()}
}
foreach($h in Import-Csv "$out/deployment-checksums.csv"){Check 'Artifact checksum matches' ((Get-FileHash -LiteralPath $h.File -Algorithm SHA256).Hash -ceq $h.SHA256) $h.File}
Check 'No forbidden payload metadata or destructive manifest' (@(Get-ChildItem "$out/deployment-payload" -Recurse -File | Where-Object {$_.Name -ne 'package.xml' -and $_.Extension -notin @('.group','.object','.sharingRules')}).Count -eq 0) 'Only approved types'
$app=Xml "$base/applications/safexpress2_0.app-meta.xml"
Check 'Confirmed app already contains Lead; no edit' ('standard-Lead' -cin @($app.CustomApplication.tabs) -and (Resolve-Path "$base/applications/safexpress2_0.app-meta.xml").Path -notin $changed) 'All original navigation/settings preserved by SHA-256'
Record 'API structure / compatibility' 'LOCALLY INSPECTED' 'Established Group, CustomObject and SharingCriteriaRule structures; official excerpts and retrieved representation; no full XSD or org deployment validation'
Record 'Live dependencies and effective access' 'OUTSTANDING' 'All memberships, org identities, target values/counts, UST1/4/8 and Dev 5 remain unverified'
Record 'Org deployment validation' 'NOT RUN' 'No Salesforce CLI or org calls executed'
$checks | Export-Csv "$out/validation-checks.csv" -NoTypeInformation
$text=@('# Local validation report - confirmed 34-rule revision','','No deployment or org validation was performed. All 34 rule definitions and approved payload structures are locally checked. Actual group memberships, live dependencies and runtime acceptance remain outstanding.','','| Check | Result | Evidence |','| --- | --- | --- |')
foreach($c in $checks){$text+="| $($c.Check) | $($c.Result) | $($c.Evidence) |"}
[IO.File]::WriteAllText("$out/validation-report.md",($text -join "`r`n"),$utf8)
$files=@();foreach($p in $added){$files += [pscustomobject]@{FullFilePath=$p;Change='Created';Purpose='Group definition only; membership not transported'}}
foreach($p in $changed){$files += [pscustomobject]@{FullFilePath=$p;Change='Modified';Purpose=$(if($p -like '*object-meta.xml'){'Lead internal/external OWD only'}else{'34 user-confirmed story sharing rules'})}}
foreach($p in Get-ChildItem $out -Recurse -File | Where-Object Name -notin @('file-change-review.csv','file-change-review.md')){$files += [pscustomobject]@{FullFilePath=$p.FullName;Change='Created for story; current revision';Purpose=$(if($p.FullName -like '*\baseline\*'){'Pre-change evidence; not a deployment artifact'}elseif($p.FullName -match '\\(deployment-payload|access-payload)\\'){'Isolated confirmed XML payload; deployment/membership checks outstanding'}else{'Review, verification or future deployment-plan artifact'})}}
foreach($name in @('file-change-review.csv','file-change-review.md')){$files += [pscustomobject]@{FullFilePath="$out\$name";Change='Created';Purpose='Full file-change inventory'}}
$files | Export-Csv "$out/file-change-review.csv" -NoTypeInformation
$text=@('# Complete file-change table','','All paths are absolute. No files outside this list were changed. Source preservation is checked against the recorded SHA-256 baseline.','','| Full file path | Created/Modified | Purpose |','| --- | --- | --- |')
foreach($f in $files){$text+="| $($f.FullFilePath) | $($f.Change) | $($f.Purpose) |"}
[IO.File]::WriteAllText("$out/file-change-review.md",($text -join "`r`n"),$utf8)
"Validated: $($changed.Count) existing source files modified; $($added.Count) created; $($deleted.Count) deleted; $($checks.Count) checks recorded."
