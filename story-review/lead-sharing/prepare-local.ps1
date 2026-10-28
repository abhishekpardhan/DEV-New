throw 'Historical initial preparation script. Superseded by update-approved.ps1 after user confirmations; do not overwrite the baseline audit.'
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$base = Join-Path $root 'force-app/main/default'
$out = $PSScriptRoot
$ns = 'http://soap.sforce.com/2006/04/metadata'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function WriteText($path, $text) { [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null; [IO.File]::WriteAllText($path, $text.Replace("`r`n", "`n").Replace("`n", "`r`n"), $utf8) }
function ReadXml($path) { $doc = New-Object System.Xml.XmlDocument; $doc.PreserveWhitespace = $true; $doc.Load($path); return ,$doc }
function Escape($s) { [Security.SecurityElement]::Escape([string]$s) }
function Table($headers,$rows) { @('| '+($headers -join ' | ')+' |','| '+(($headers | ForEach-Object {'---'}) -join ' | ')+' |') + @($rows | ForEach-Object {'| '+($_ -join ' | ')+' |'}) }
$regionLines = @'
APT|ANDHRA PRADESH - TELANGANA
BJO|BIHAR - JHARKHAND - ORISSA
DLI|DELHI
GJT|GUJARAT
HRN|HARYANA
JKH|JAMMU KASHMIR - HIMACHAL PRADESH
KRL|KERALA
KTK|KARNATAKA
MHG|MAHARASHTRA - GOA
MPC|MADHYA PRADESH - CHHATTISGARH
MUM|MUMBAI
NRE|NORTH EAST
PBC|PUNJAB - CHANDIGARH
RJN|RAJASTHAN
TNP|TAMILNADU - PUDUCHERRY
UKH|UTTARAKHAND
UPR|UTTAR PRADESH
WBS|WEST BENGAL - SIKKIM
'@
$regions = @($regionLines -split "`r?`n" | ForEach-Object {$p=$_ -split '\|'; [pscustomobject]@{Code=$p[0];Value=$p[1]}})
$roleTypes = @('Regional Manager','Regional ICM Manager','Regional New Sales Manager','Regional Retail Manager')
$roles = @(Get-ChildItem "$base/roles/*.xml" | ForEach-Object {$x=ReadXml $_.FullName; [pscustomobject]@{API=$_.Name.Replace('.role-meta.xml','');Label=[string]$x.Role.name;Parent=[string]$x.Role.parentRole;Path=$_.FullName}})
$groupsBefore = @(Get-ChildItem "$base/groups/*.xml" | ForEach-Object {$x=ReadXml $_.FullName; [pscustomobject]@{API=$_.Name.Replace('.group-meta.xml','');Label=[string]$x.Group.name;Hierarchy=[string]$x.Group.doesIncludeBosses;Membership='REQUIRES LIVE ORG VERIFICATION: not serialized by Group metadata';Path=$_.FullName}})
$groupsBefore | Export-Csv "$out/existing-group-inventory.csv" -NoTypeInformation
if (@($groupsBefore | Group-Object API | Where-Object Count -gt 1).Count -or @($groupsBefore | Group-Object Label | Where-Object Count -gt 1).Count) {throw 'Duplicate group API names or labels require review'}
$values = @{}
foreach($pair in @(@('Region__c','Region'),@('Vertical__c','Vertical_Global'),@('Sub_Vertical__c','Sub_Vertical'))) {
    $x=ReadXml "$base/globalValueSets/$($pair[1]).globalValueSet-meta.xml"
    $values[$pair[0]]=@($x.GlobalValueSet.customValue)
}
$source = ReadXml "$base/standardValueSets/LeadSource.standardValueSet-meta.xml"
$values['LeadSource']=@($source.StandardValueSet.standardValue)
function CheckValue($field,$value) {
    $match=@($values[$field] | Where-Object { [string]$_.fullName -ceq $value })
    if($match.Count -eq 0){return 'BLOCKED: exact value missing'}
    if($match.Count -ne 1){return 'BLOCKED: duplicate value'}
    if([string]$match[0].isActive -eq 'false'){return 'BLOCKED: exact value inactive'}
    return 'VERIFIED'
}
$membership = @()
foreach($r in $regions) { foreach($type in $roleTypes) {
    $matches=@($roles | Where-Object Label -ceq "$type $($r.Code)")
    if($matches.Count -ne 1){throw "Ambiguous role: $type $($r.Code)"}
    $role=$matches[0]
    $membership += [pscustomobject]@{RegionCode=$r.Code;PublicGroupAPIName="SG_RGN_$($r.Code)_RM";RoleType=$type;RoleDeveloperName=$role.API;MembershipType='Role';VerifiedSource=$role.Path;Status='VERIFIED role identity locally; BLOCKED membership: not supported by Group Metadata API'}
} }
$membership | Export-Csv "$out/group-membership-review.csv" -NoTypeInformation
$hierarchy=@($membership | ForEach-Object {$m=$_;$r=$roles | Where-Object API -ceq $m.RoleDeveloperName; [pscustomobject]@{Region=$m.RegionCode;Role=$r.API;Label=$r.Label;Parent=$r.Parent;ParentExistsLocally=($r.Parent -cin $roles.API);Status= $(if($m.RegionCode -eq 'GJT' -and $r.Parent -eq 'Regional_Manager_MUM'){'REVIEW: GJT role reports to MUM'}else{'VERIFY LIVE'})}})
$hierarchy | Export-Csv "$out/role-hierarchy-review.csv" -NoTypeInformation
$legacy=ReadXml "$base/sharingRules/Lead__c.sharingRules-meta.xml"
$vh=@($legacy.SharingRules.sharingCriteriaRules | Where-Object { $_.sharedTo.group -like 'VH_*' })
if($vh.Count -ne 14){throw 'Expected exactly 14 legacy VH criteria rules'}
$planned=@()
foreach($r in $regions) {
    $planned += [pscustomobject]@{Name="SR_Lead_RGN_$($r.Code)";Source='Story LLD supplied in request';SourceRule='';Group="SG_RGN_$($r.Code)_RM";Access='Edit';Logic='1';Conditions=@([pscustomobject]@{field='Region__c';operation='equals';value=$r.Value});Status=(CheckValue 'Region__c' $r.Value);IncludeAll='false'}
}
foreach($v in $vh) {
    $conditions=@($v.criteriaItems | ForEach-Object {[pscustomobject]@{field=[string]$_.field;operation=[string]$_.operation;value=[string]$_.value}})
    if(@($conditions | Where-Object field -eq 'Type__c').Count){throw 'Type rule selected'}
    $status=@($conditions | ForEach-Object {CheckValue $_.field $_.value} | Where-Object {$_ -ne 'VERIFIED'})
    $logic=[string]$v.booleanFilter
    if(!$logic){$logic=(1..$conditions.Count) -join ' AND '}
    $planned += [pscustomobject]@{Name=('SR_Lead_'+[string]$v.sharedTo.group);Source='Lead__c';SourceRule=[string]$v.fullName;Group=[string]$v.sharedTo.group;Access='Edit';Logic=$logic;Conditions=$conditions;Status=$(if($status.Count){($status | Select-Object -Unique) -join '; '}else{'VERIFIED'});IncludeAll=[string]$v.includeRecordsOwnedByAll}
}
$planned += [pscustomobject]@{Name='SR_Lead_Alliance_Partner';Source='Story LLD supplied in request';SourceRule='';Group='Alliance_Partner_Management';Access='Read';Logic='1';Conditions=@([pscustomobject]@{field='Vertical__c';operation='equals';value='ALLIANCE PARTNER MANAGEMENT'});Status=(CheckValue 'Vertical__c' 'ALLIANCE PARTNER MANAGEMENT');IncludeAll='false'}
$planned += [pscustomobject]@{Name='SR_Lead_Safexperience_Team';Source='Story LLD supplied in request';SourceRule='';Group='Safexperience_Team';Access='Edit';Logic='1 OR 2';Conditions=@([pscustomobject]@{field='LeadSource';operation='equals';value='Web'},[pscustomobject]@{field='LeadSource';operation='equals';value='Safexperience Centre'});Status=(CheckValue 'LeadSource' 'Web');IncludeAll='false'}
if($planned.Count -ne 34 -or @($planned | Group-Object Name | Where-Object Count -gt 1).Count){throw 'Invalid planned rule inventory'}
$oldRules=ReadXml "$base/sharingRules/Lead.sharingRules-meta.xml"
if(@($oldRules.SharingRules.ChildNodes | Where-Object NodeType -eq Element).Count){throw 'Existing Lead rules require nonempty merge; stop'}
$eligible=@($planned | Where-Object Status -eq VERIFIED)
if($eligible.Count -ne 18){throw "Review eligibility changed: $($eligible.Count)"}
# Audit is completed before the first metadata write. Group definitions cannot express membership.
$created=@()
foreach($group in @($regions | ForEach-Object {"SG_RGN_$($_.Code)_RM"}) + @('Safexperience_Team')) {
    $path="$base/groups/$group.group-meta.xml"
    if(Test-Path $path){throw "Unexpected existing story group: $group"}
    $label=if($group -eq 'Safexperience_Team'){'Safexperience Team'}else{$group}
    WriteText $path "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<Group xmlns=`"$ns`">`n    <doesIncludeBosses>true</doesIncludeBosses>`n    <name>$label</name>`n</Group>`n"
    $created += $path
}
$ruleXml=@()
foreach($rule in $eligible) {
    $ruleXml += '    <sharingCriteriaRules>'
    $ruleXml += "        <fullName>$($rule.Name)</fullName>"
    $ruleXml += "        <accessLevel>$($rule.Access)</accessLevel>"
    $ruleXml += "        <label>$($rule.Name)</label>"
    $ruleXml += "        <sharedTo>`n            <group>$($rule.Group)</group>`n        </sharedTo>"
    if($rule.Conditions.Count -gt 1){$ruleXml += "        <booleanFilter>$(Escape $rule.Logic)</booleanFilter>"}
    foreach($c in $rule.Conditions) {$ruleXml += "        <criteriaItems>`n            <field>$($c.field)</field>`n            <operation>$($c.operation)</operation>`n            <value>$(Escape $c.value)</value>`n        </criteriaItems>"}
    $ruleXml += "        <includeRecordsOwnedByAll>$($rule.IncludeAll)</includeRecordsOwnedByAll>"
    $ruleXml += '    </sharingCriteriaRules>'
}
WriteText "$base/sharingRules/Lead.sharingRules-meta.xml" ("<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<SharingRules xmlns=`"$ns`">`n"+($ruleXml -join "`n")+"`n</SharingRules>`n")
$objectPath="$base/objects/Lead/Lead.object-meta.xml"
$objectText=[IO.File]::ReadAllText($objectPath)
if(-not $objectText.Contains('<sharingModel>ReadWriteTransfer</sharingModel>') -or -not $objectText.Contains('<externalSharingModel>ReadWriteTransfer</externalSharingModel>')){throw 'OWD baseline changed'}
[IO.File]::WriteAllText($objectPath, ($objectText.Replace('<sharingModel>ReadWriteTransfer</sharingModel>','<sharingModel>Private</sharingModel>').Replace('<externalSharingModel>ReadWriteTransfer</externalSharingModel>','<externalSharingModel>Private</externalSharingModel>')), $utf8)
$csv=@()
foreach($rule in $planned){$i=0;foreach($c in $rule.Conditions){$i++;$csv += [pscustomobject]@{RuleAPIName=$rule.Name;SourceObject=$(if($rule.Source -eq 'Lead__c'){'Lead__c'}else{'Lead (story requirement)'});TargetObject='Lead';Field=$c.field;Operator=$c.operation;Value=$c.value;TargetGroup=$rule.Group;AccessLevel=$rule.Access;VerificationStatus="$($rule.Status); condition $i; filter=$($rule.Logic); sourceRule=$($rule.SourceRule); includeRecordsOwnedByAll=$($rule.IncludeAll); live memberships unverified"}}}
$csv | Export-Csv "$out/sharing-rule-review.csv" -NoTypeInformation
$regionReview=@($regions | ForEach-Object {[pscustomobject]@{Region=$_.Code;RequiredValue=$_.Value;Status=(CheckValue 'Region__c' $_.Value);Source="$base/globalValueSets/Region.globalValueSet-meta.xml"}})
$regionReview | Export-Csv "$out/region-value-review.csv" -NoTypeInformation
$fields=@()
foreach($f in @('Region__c','Vertical__c','Sub_Vertical__c','LeadSource')){$p="$base/objects/Lead/fields/$f.field-meta.xml";$x=ReadXml $p;$fields += [pscustomobject]@{Field="Lead.$f";ExistsLocally=$true;Type=[string]$x.CustomField.type;ValueSet=$(if($f -eq 'LeadSource'){'LeadSource (StandardValueSet)'}else{[string]$x.CustomField.valueSet.valueSetName});Source=$p;Status='PARTIAL: inspect rule and value audit'}}
$fields | Export-Csv "$out/field-review.csv" -NoTypeInformation
$app=ReadXml "$base/applications/safexpress2_0.app-meta.xml"
if('standard-Lead' -cnotin @($app.CustomApplication.tabs)){throw 'Confirmed app does not contain Lead'}
$manifest="<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<Package xmlns=`"$ns`">`n    <types>`n"
foreach($g in $created){$manifest+="        <members>$([IO.Path]::GetFileName($g).Replace('.group-meta.xml',''))</members>`n"}
$manifest+="        <name>Group</name>`n    </types>`n    <types>`n        <members>Lead</members>`n        <name>CustomObject</name>`n    </types>`n    <types>`n"
foreach($r in $eligible){$manifest+="        <members>Lead.$($r.Name)</members>`n"}
$manifest+="        <name>SharingCriteriaRule</name>`n    </types>`n    <version>67.0</version>`n</Package>`n"
WriteText "$out/manifest/lead-sharing-story.xml" $manifest
# Isolated Metadata API payload avoids source conversion including Lead fields and other children.
WriteText "$out/deployment-payload/package.xml" $manifest
WriteText "$out/deployment-payload/objects/Lead.object" "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<CustomObject xmlns=`"$ns`">`n    <externalSharingModel>Private</externalSharingModel>`n    <sharingModel>Private</sharingModel>`n</CustomObject>`n"
foreach($g in $created){Copy-Item -LiteralPath $g -Destination (New-Item -ItemType Directory -Force "$out/deployment-payload/groups").FullName; $copy="$out/deployment-payload/groups/$([IO.Path]::GetFileName($g))"; Move-Item -LiteralPath $copy -Destination $copy.Replace('.group-meta.xml','.group')}
New-Item -ItemType Directory -Force "$out/deployment-payload/sharingRules" | Out-Null
Copy-Item "$base/sharingRules/Lead.sharingRules-meta.xml" "$out/deployment-payload/sharingRules/Lead.sharingRules"
$planned | ConvertTo-Json -Depth 8 | Set-Content "$out/planned-rules.json" -Encoding UTF8
$membership | ConvertTo-Json -Depth 4 | Set-Content "$out/planned-memberships.json" -Encoding UTF8
Write-Output "Prepared $($created.Count) group definitions; $($eligible.Count) rules; one Lead OWD component. Memberships and blocked rules remain incomplete."
