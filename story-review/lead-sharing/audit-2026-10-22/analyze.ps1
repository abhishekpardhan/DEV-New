$ErrorActionPreference='Stop'
$out=$PSScriptRoot
$review=(Resolve-Path "$out/..").Path
$root=(Resolve-Path "$review/../..").Path
$base="$root/force-app/main/default"
function Xml($path){[xml][IO.File]::ReadAllText($path)}
function Live($name){$j=Get-Content "$out/$name.json" -Raw | ConvertFrom-Json;if($j.status -ne 0 -or !$j.result.done){throw "Invalid live evidence $name"};return $j.result.records}
$groups=@(Live 'groups');$members=@(Live 'members');$roles=@(Live 'roles');$roleGroups=@(Live 'role-groups')
$expected=Import-Csv "$review/group-membership-review.csv"
$membershipResults=@()
foreach($e in $expected){
    $g=@($groups | Where-Object DeveloperName -ceq $e.PublicGroupAPIName)
    $r=@($roles | Where-Object DeveloperName -ceq $e.RoleDeveloperName)
    $rg=@($roleGroups | Where-Object {$_.Type -ceq 'Role' -and $_.RelatedId -cin @($r.Id)})
    $gm=@($members | Where-Object {$_.GroupId -cin @($g.Id) -and $_.UserOrGroupId -cin @($rg.Id)})
    $membershipResults += [pscustomobject]@{Region=$e.RegionCode;Group=$e.PublicGroupAPIName;Role=$e.RoleDeveloperName;RoleLabel=($r.Name -join ';');RoleId=($r.Id -join ';');RoleGroupId=($rg.Id -join ';');MembershipId=($gm.Id -join ';');Status=$(if($g.Count -eq 1 -and $r.Count -eq 1 -and $rg.Count -eq 1 -and $gm.Count -eq 1 -and $g[0].DoesIncludeBosses){'VERIFIED LIVE'}else{'FAIL'});ExpectedMembershipType='Role'}
}
$membershipResults | Export-Csv "$out/regional-memberships.csv" -NoTypeInformation
$groupResults=@();foreach($g in $groups){$gm=@($members | Where-Object GroupId -ceq $g.Id);$planned=@($membershipResults | Where-Object Group -ceq $g.DeveloperName);$extra=@($gm | Where-Object {$_.Id -cnotin @($planned.MembershipId)});$groupResults += [pscustomobject]@{Group=$g.DeveloperName;Label=$g.Name;Id=$g.Id;Hierarchy=$g.DoesIncludeBosses;DirectMembers=$gm.Count;ExpectedRolesVerified=@($planned | Where-Object Status -eq 'VERIFIED LIVE').Count;ExtraMembersForRegionalGroup=$(if($g.DeveloperName -like 'SG_RGN_*'){$extra.Count}else{'N/A'});Status=$(if($g.DeveloperName -like 'SG_RGN_*'){if($planned.Count -eq 4 -and $gm.Count -eq 4 -and $extra.Count -eq 0 -and @($planned | Where-Object Status -ne 'VERIFIED LIVE').Count -eq 0){'VERIFIED LIVE'}else{'FAIL'}}elseif($g.DeveloperName -eq 'Safexperience_Team'){if($gm.Count -eq 0 -and $g.DoesIncludeBosses -and $g.Name -ceq 'Safexperience Team'){'VERIFIED LIVE - initially empty'}else{'REVIEW'}}elseif($gm.Count -eq 0){'EMPTY - no users receive access through this group'}else{'EXISTS - membership business suitability unverified'})}}
$groupResults | Sort-Object Group | Export-Csv "$out/group-status.csv" -NoTypeInformation
$plan=Get-Content "$review/planned-rules.json" -Raw | ConvertFrom-Json
$lead=Xml "$base/sharingRules/Lead.sharingRules-meta.xml"
$legacy=Xml "$base/sharingRules/Lead__c.sharingRules-meta.xml"
$ruleResults=@();foreach($p in $plan){$r=@($lead.SharingRules.sharingCriteriaRules | Where-Object fullName -ceq $p.Name);$ok=$r.Count -eq 1;$notes=@();if($ok){
    $ok=$r[0].accessLevel -ceq $p.Access -and $r[0].sharedTo.group -ceq $p.Group -and $r[0].includeRecordsOwnedByAll -ceq $p.IncludeAll
    $c=@($r[0].criteriaItems);$ok=$ok -and $c.Count -eq $p.Conditions.Count
    for($i=0;$i -lt [Math]::Min($c.Count,$p.Conditions.Count);$i++){$ok=$ok -and [string]$c[$i].field -ceq $p.Conditions[$i].field -and [string]$c[$i].operation -ceq $p.Conditions[$i].operation -and [string]$c[$i].value -ceq $p.Conditions[$i].value}
    $logic=if($r[0].booleanFilter){[string]$r[0].booleanFilter}else{(1..$c.Count) -join ' AND '};$ok=$ok -and $logic -ceq $p.Logic
    if($p.Source -ceq 'Lead__c'){$l=@($legacy.SharingRules.sharingCriteriaRules | Where-Object fullName -ceq $p.SourceRule);$ok=$ok -and $l.Count -eq 1;if($l.Count -eq 1){$lc=@($l[0].criteriaItems);$ok=$ok -and $lc.Count -eq $c.Count;for($i=0;$i -lt [Math]::Min($lc.Count,$c.Count);$i++){$ok=$ok -and [string]$lc[$i].field -ceq [string]$c[$i].field -and [string]$lc[$i].operation -ceq [string]$c[$i].operation -and [string]$lc[$i].value -ceq [string]$c[$i].value}}}
}
    $ruleResults += [pscustomobject]@{Rule=$p.Name;Status=$(if($ok){'MATCHES APPROVED DESIGN IN RETRIEVED XML'}else{'MISMATCH'});Criteria=(@($p.Conditions | ForEach-Object {"$($_.field) $($_.operation) $($_.value)"}) -join '; ');Logic=$p.Logic;Access=$p.Access;Group=$p.Group;LegacyStatus=$p.Status;Evidence="$base/sharingRules/Lead.sharingRules-meta.xml"}
}
$ruleResults | Export-Csv "$out/sharing-rules.csv" -NoTypeInformation
$fields=@();foreach($name in @('Region__c','Vertical__c','Sub_Vertical__c','LeadSource','Assignment_Evaluated__c','Pincode_Lookup_Status__c','GST_Status__c','Assign_to_Central_Desk__c')){$path="$base/objects/Lead/fields/$name.field-meta.xml";$exists=Test-Path $path;$f=if($exists){Xml $path}else{$null};$fields += [pscustomobject]@{Field="Lead.$name";ExistsLocally=$exists;Type=[string]$f.CustomField.type;Required=[string]$f.CustomField.required;ValueSet=[string]$f.CustomField.valueSet.valueSetName;Evidence=$path}}
$fields | Export-Csv "$out/fields.csv" -NoTypeInformation
$psRows=@();foreach($file in Get-ChildItem "$base/permissionsets/*.xml"){$p=Xml $file.FullName;$leadPerm=@($p.PermissionSet.objectPermissions | Where-Object object -ceq 'Lead');$tab=@($p.PermissionSet.tabSettings | Where-Object tab -ceq 'standard-Lead');$psRows += [pscustomobject]@{PermissionSet=$file.Name.Replace('.permissionset-meta.xml','');Label=[string]$p.PermissionSet.label;LeadPermissionPresent=$leadPerm.Count -gt 0;Read=(@($leadPerm.allowRead) -contains 'true');Create=(@($leadPerm.allowCreate) -contains 'true');Edit=(@($leadPerm.allowEdit) -contains 'true');Delete=(@($leadPerm.allowDelete) -contains 'true');ViewAll=(@($leadPerm.viewAllRecords) -contains 'true');ModifyAll=(@($leadPerm.modifyAllRecords) -contains 'true');TabVisibility=($tab.visibility -join ';');SystemFieldFLS=(@($p.PermissionSet.fieldPermissions | Where-Object {$_.field -cin @('Lead.Assignment_Evaluated__c','Lead.Pincode_Lookup_Status__c','Lead.GST_Status__c')} | ForEach-Object {"$($_.field):read=$($_.readable),edit=$($_.editable)"}) -join ';');GlobalViewAll=(@($p.PermissionSet.userPermissions | Where-Object {$_.name -ceq 'ViewAllData' -and $_.enabled -eq 'true'}).Count -gt 0);GlobalModifyAll=(@($p.PermissionSet.userPermissions | Where-Object {$_.name -ceq 'ModifyAllData' -and $_.enabled -eq 'true'}).Count -gt 0);Evidence=$file.FullName}}
$psRows | Export-Csv "$out/permission-sets.csv" -NoTypeInformation
$psgRows=@();foreach($file in Get-ChildItem "$base/permissionsetgroups/PSG_*.xml"){$p=Xml $file.FullName;$parts=@($psRows | Where-Object {$_.PermissionSet -cin @($p.PermissionSetGroup.permissionSets)});$psgRows += [pscustomobject]@{Group=$file.Name.Replace('.permissionsetgroup-meta.xml','');PermissionSets=(@($p.PermissionSetGroup.permissionSets) -join ';');Read=(@($parts | Where-Object Read).Count -gt 0);Create=(@($parts | Where-Object Create).Count -gt 0);Edit=(@($parts | Where-Object Edit).Count -gt 0);Delete=(@($parts | Where-Object Delete).Count -gt 0);ViewAll=(@($parts | Where-Object ViewAll).Count -gt 0);ModifyAll=(@($parts | Where-Object ModifyAll).Count -gt 0);TabVisible=(@($parts | Where-Object TabVisibility -eq 'Visible').Count -gt 0);Scope='Candidate group; persona roster/assignments/muting not established';Evidence=$file.FullName}}
$psgRows | Export-Csv "$out/permission-set-groups.csv" -NoTypeInformation
$pageRows=@();foreach($file in Get-ChildItem "$base/flexipages/*.xml"){$p=Xml $file.FullName;if($p.FlexiPage.sobjectType -ceq 'Lead'){foreach($fi in $p.SelectNodes('//*[local-name()="fieldInstance"]')){$behavior=@($fi.fieldInstanceProperties | Where-Object name -eq 'uiBehavior');$pageRows += [pscustomobject]@{Page=$file.Name.Replace('.flexipage-meta.xml','');Field=[string]$fi.fieldItem;UIBehavior=($behavior.value -join ';');Evidence=$file.FullName}}}}
$pageRows | Export-Csv "$out/dynamic-form-fields.csv" -NoTypeInformation
$layoutRows=@();foreach($file in Get-ChildItem "$base/layouts/Lead-*.xml"){$p=Xml $file.FullName;foreach($fi in $p.SelectNodes('//*[local-name()="layoutItems"]')){if($fi.field){$layoutRows += [pscustomobject]@{Layout=$file.Name;Field=[string]$fi.field;Behavior=[string]$fi.behavior;Evidence=$file.FullName}}}}
$layoutRows | Export-Csv "$out/lead-layout-fields.csv" -NoTypeInformation
$vrRows=@();foreach($file in Get-ChildItem "$base/objects/Lead/validationRules/*.xml"){$v=(Xml $file.FullName).ValidationRule;$vrRows += [pscustomobject]@{Rule=[string]$v.fullName;Active=[string]$v.active;Formula=[string]$v.errorConditionFormula;Message=[string]$v.errorMessage;Evidence=$file.FullName}}
$vrRows | Export-Csv "$out/validation-rules.csv" -NoTypeInformation
$flowRows=@();foreach($file in Get-ChildItem "$base/flows/*.xml"){$f=Xml $file.FullName;if($f.Flow.start.object -ceq 'Lead'){$flowRows += [pscustomobject]@{Flow=$file.Name;Status=[string]$f.Flow.status;TriggerType=[string]$f.Flow.start.triggerType;RecordTriggerType=[string]$f.Flow.start.recordTriggerType;HasOwnerIdReference=$file.FullName -and ([IO.File]::ReadAllText($file.FullName) -match 'OwnerId');Evidence=$file.FullName}}}
$flowRows | Export-Csv "$out/lead-triggered-flows.csv" -NoTypeInformation
Write-Output "Regional membership matches: $(@($membershipResults | Where-Object Status -eq 'VERIFIED LIVE').Count)/72; groups exact: $(@($groupResults | Where-Object Status -eq 'VERIFIED LIVE').Count)/18"
Write-Output "Rule matches: $(@($ruleResults | Where-Object Status -ne 'MISMATCH').Count)/34"
$psRows | Where-Object {$_.PermissionSet -in @('PS_Lead_Management','BDM','Sales_User','PS_AreaMgr_Delta','PS_RegMgr_Delta','PS_BDM_Delta')} | Format-Table PermissionSet,Read,Create,Edit,Delete,ViewAll,ModifyAll,TabVisibility
$psgRows | Where-Object {$_.Group -in @('PSG_AreaManager','PSG_RegionalManager','PSG_TerritoryManager')} | Format-Table Group,Read,Create,Edit,Delete,ViewAll,ModifyAll,TabVisible
$fields | Format-Table Field,ExistsLocally,Type
