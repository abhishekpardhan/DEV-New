$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$base = "$root/force-app/main/default"
$out = $PSScriptRoot
$ns = 'http://soap.sforce.com/2006/04/metadata'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function WriteText($path,$text) { [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null; [IO.File]::WriteAllText($path,($text -join "`r`n"),$utf8) }
function Xml($path) {$x=New-Object System.Xml.XmlDocument;$x.PreserveWhitespace=$true;$x.Load($path);return ,$x}
function Esc($s) {[Security.SecurityElement]::Escape([string]$s)}
$plan=Get-Content "$out/planned-rules.json" -Raw | ConvertFrom-Json
if($plan.Count -ne 34){throw 'Expected 34 planned rules'}
$approvedRegions=@{SR_Lead_RGN_BJO='BIHAR - JHARKHAND - ODISHA';SR_Lead_RGN_KRL='KERALAM';SR_Lead_RGN_JKH='JK - HP - LADAKH'}
$sets=@{}
foreach($pair in @(@('Region__c','Region'),@('Vertical__c','Vertical_Global'),@('Sub_Vertical__c','Sub_Vertical'))) {$x=Xml "$base/globalValueSets/$($pair[1]).globalValueSet-meta.xml";$sets[$pair[0]]=@($x.GlobalValueSet.customValue)}
$x=Xml "$base/standardValueSets/LeadSource.standardValueSet-meta.xml";$sets['LeadSource']=@($x.StandardValueSet.standardValue)
$legacy=Xml "$base/sharingRules/Lead__c.sharingRules-meta.xml"
foreach($r in $plan) {
    if($approvedRegions.ContainsKey($r.Name)){$r.Conditions[0].value=$approvedRegions[$r.Name]}
    if($r.Name -ceq 'SR_Lead_Safexperience_Team'){$r.Conditions[0].value='Website';$r.Logic='1 OR 2'}
    $inactive=$false
    foreach($c in $r.Conditions) {
        $match=@($sets[$c.field] | Where-Object {[string]$_.fullName -ceq $c.value})
        if($match.Count -ne 1){throw "Unverified exact value for $($r.Name): $($c.value)"}
        if([string]$match[0].isActive -eq 'false'){$inactive=$true}
    }
    if($inactive -and $r.Source -cne 'Lead__c'){throw "Unapproved inactive value: $($r.Name)"}
    $r.Status=if($inactive){'APPROVED LEGACY INACTIVE: exact retrieved criteria retained by user instruction'}else{'VERIFIED'}
    if($r.Source -ceq 'Lead__c'){
        $v=@($legacy.SharingRules.sharingCriteriaRules | Where-Object fullName -ceq $r.SourceRule)
        if($v.Count -ne 1){throw 'Legacy source missing'}
        $vc=@($v[0].criteriaItems)
        if($vc.Count -ne $r.Conditions.Count -or [string]$v[0].sharedTo.group -cne $r.Group){throw 'Legacy rule mapping differs'}
        for($i=0;$i -lt $vc.Count;$i++){if([string]$vc[$i].field -cne $r.Conditions[$i].field -or [string]$vc[$i].operation -cne $r.Conditions[$i].operation -or [string]$vc[$i].value -cne $r.Conditions[$i].value){throw 'Legacy condition changed'}}
    }
    if($r.IncludeAll -cne 'false'){throw 'Owner scope changed unexpectedly'}
    if(!(Test-Path "$base/groups/$($r.Group).group-meta.xml")){throw "Missing group definition $($r.Group)"}
}
$sourcePath="$base/sharingRules/Lead.sharingRules-meta.xml"
$current=Xml $sourcePath
$existing=@($current.SharingRules.sharingCriteriaRules)
if($existing.Count -notin @(18,34)){throw 'Unexpected Lead rule inventory; review before editing'}
foreach($r in $existing){
    $p=@($plan | Where-Object Name -ceq $r.fullName)
    if($p.Count -ne 1 -or $p[0].Access -cne $r.accessLevel -or $p[0].Group -cne $r.sharedTo.group){throw 'Existing rule differs from reviewed plan'}
    $c=@($r.criteriaItems)
    if($c.Count -ne $p[0].Conditions.Count){throw 'Existing condition count differs'}
    for($i=0;$i -lt $c.Count;$i++){if([string]$c[$i].field -cne $p[0].Conditions[$i].field -or [string]$c[$i].operation -cne $p[0].Conditions[$i].operation -or [string]$c[$i].value -cne $p[0].Conditions[$i].value){throw 'Existing condition differs'}}
}
if(!(Test-Path "$out/baseline/pre-confirmation-Lead.sharingRules-meta.xml")){Copy-Item -LiteralPath $sourcePath -Destination "$out/baseline/pre-confirmation-Lead.sharingRules-meta.xml"}
$add=@($plan | Where-Object {$_.Name -cnotin @($existing.fullName)})
$blocks=@()
foreach($r in $add){
    $b=@('    <sharingCriteriaRules>',"        <fullName>$($r.Name)</fullName>","        <accessLevel>$($r.Access)</accessLevel>","        <label>$($r.Name)</label>",'        <sharedTo>',"            <group>$($r.Group)</group>",'        </sharedTo>')
    if($r.Conditions.Count -gt 1){$b+="        <booleanFilter>$($r.Logic)</booleanFilter>"}
    foreach($c in $r.Conditions){$b+=@('        <criteriaItems>',"            <field>$($c.field)</field>","            <operation>$($c.operation)</operation>","            <value>$(Esc $c.value)</value>",'        </criteriaItems>')}
    $b+=@('        <includeRecordsOwnedByAll>false</includeRecordsOwnedByAll>','    </sharingCriteriaRules>')
    $blocks+=$b
}
if($add.Count){$text=[IO.File]::ReadAllText($sourcePath);$text=$text.Replace('</SharingRules>',(($blocks -join "`r`n")+"`r`n</SharingRules>"));WriteText $sourcePath $text}
$plan | ConvertTo-Json -Depth 8 | Set-Content "$out/planned-rules.json" -Encoding UTF8
$csv=@();foreach($r in $plan){$i=0;foreach($c in $r.Conditions){$i++;$csv += [pscustomobject]@{RuleAPIName=$r.Name;SourceObject=$(if($r.Source -ceq 'Lead__c'){'Lead__c'}else{'Lead (approved story requirement)'});TargetObject='Lead';Field=$c.field;Operator=$c.operation;Value=$c.value;TargetGroup=$r.Group;AccessLevel=$r.Access;VerificationStatus="$($r.Status); condition $i; filter=$($r.Logic); sourceRule=$($r.SourceRule); includeRecordsOwnedByAll=false; live memberships unverified"}}}
$csv | Export-Csv "$out/sharing-rule-review.csv" -NoTypeInformation
$rr=Import-Csv "$out/region-value-review.csv";foreach($r in $rr){$p=$plan | Where-Object Name -ceq "SR_Lead_RGN_$($r.Region)";$r.RequiredValue=$p.Conditions[0].value;$r.Status='VERIFIED: approved exact active value'};$rr | Export-Csv "$out/region-value-review.csv" -NoTypeInformation
$fr=Import-Csv "$out/field-review.csv";foreach($f in $fr){$f.Status=if($f.Field -in @('Lead.Vertical__c','Lead.Sub_Vertical__c')){'VERIFIED locally; inactive legacy criteria explicitly approved, picklists unchanged'}else{'VERIFIED locally: approved active values'}};$fr | Export-Csv "$out/field-review.csv" -NoTypeInformation
$hr=Import-Csv "$out/role-hierarchy-review.csv";foreach($h in $hr){if($h.Region -eq 'GJT' -and $h.Parent -eq 'Regional_Manager_MUM'){$h.Status='USER DIRECTED NO HIERARCHY CHANGE; existing GJT -> MUM retained; live state unverified'}};$hr | Export-Csv "$out/role-hierarchy-review.csv" -NoTypeInformation
$members=@(Import-Csv "$out/group-membership-review.csv")
$checklist=@();foreach($m in $members){$x=Xml $m.VerifiedSource;$checklist += [pscustomobject]@{RegionCode=$m.RegionCode;PublicGroupAPIName=$m.PublicGroupAPIName;RoleType=$m.RoleType;RoleLabel=[string]$x.Role.name;RoleDeveloperName=$m.RoleDeveloperName;MembershipType='Role';DEVAdded='NOT PERFORMED';DEVVerified='NOT VERIFIED';QAAdded='NOT PERFORMED';QAVerified='NOT VERIFIED';VerifiedSource=$m.VerifiedSource}}
$checklist | Export-Csv "$out/membership-setup-checklist.csv" -NoTypeInformation
$groupNames=@($members.PublicGroupAPIName | Select-Object -Unique)+@('Safexperience_Team')
function Manifest($groups,$rules,$object) {
    $lines=@('<?xml version="1.0" encoding="UTF-8"?>',"<Package xmlns=`"$ns`">")
    if($groups.Count){$lines+='    <types>';foreach($g in $groups){$lines+="        <members>$g</members>"};$lines+=@('        <name>Group</name>','    </types>')}
    if($object){$lines+=@('    <types>','        <members>Lead</members>','        <name>CustomObject</name>','    </types>')}
    if($rules.Count){$lines+='    <types>';foreach($r in $rules){$lines+="        <members>Lead.$($r.Name)</members>"};$lines+=@('        <name>SharingCriteriaRule</name>','    </types>')}
    $lines+=@('    <version>67.0</version>','</Package>');return $lines
}
$full=Manifest $groupNames $plan $true
$groupManifest=Manifest $groupNames @() $false
$accessManifest=Manifest @() $plan $true
WriteText "$out/manifest/lead-sharing-story.xml" $full
WriteText "$out/manifest/lead-sharing-groups.xml" $groupManifest
WriteText "$out/deployment-payload/package.xml" $full
Copy-Item -LiteralPath $sourcePath -Destination "$out/deployment-payload/sharingRules/Lead.sharingRules"
foreach($g in $groupNames){Copy-Item -LiteralPath "$base/groups/$g.group-meta.xml" -Destination "$out/deployment-payload/groups/$g.group"}
WriteText "$out/access-payload/package.xml" $accessManifest
WriteText "$out/access-payload/objects/Lead.object" ([IO.File]::ReadAllText("$out/deployment-payload/objects/Lead.object"))
WriteText "$out/access-payload/sharingRules/Lead.sharingRules" ([IO.File]::ReadAllText($sourcePath))
Compress-Archive -Path "$out/deployment-payload/*" -DestinationPath "$out/lead-sharing-metadata.zip" -Force
Compress-Archive -Path "$out/access-payload/*" -DestinationPath "$out/lead-sharing-access.zip" -Force
$hashes=@();foreach($p in @(Get-ChildItem "$out/deployment-payload","$out/access-payload" -Recurse -File)+@(Get-Item "$out/lead-sharing-metadata.zip","$out/lead-sharing-access.zip","$out/manifest/lead-sharing-groups.xml")){$hashes+=[pscustomobject]@{File=$p.FullName;SHA256=(Get-FileHash -LiteralPath $p.FullName -Algorithm SHA256).Hash}}
$hashes | Export-Csv "$out/deployment-checksums.csv" -NoTypeInformation
Write-Output "Local update complete: $($add.Count) rules appended; 34 planned/prepared; 19 group definitions; OWD unchanged from prior local Private/Private proposal. No org operations."
