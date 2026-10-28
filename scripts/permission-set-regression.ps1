param([switch]$Fix, [ValidateSet('Unspecified','ReadOnly','Edit')][string]$JourneyAccess='Unspecified')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path $root 'force-app/main/default'
$out=Join-Path $root 'permission-audit'
[void][IO.Directory]::CreateDirectory($out)
$expected=@{}
function Set-Matrix($name,$spec){
    $map=@{}
    foreach($item in $spec.Split(' ',[StringSplitOptions]::RemoveEmptyEntries)){$o,$r=$item.Split(':');$map[$o]=$r}
    $expected[$name]=$map
}
function Copy-Matrix($name,$source,$remove,$overrides){
    $map=@{};foreach($key in $expected[$source].Keys){$map[$key]=$expected[$source][$key]}
    foreach($key in $remove){$map.Remove($key)}
    foreach($item in $overrides.Split(' ',[StringSplitOptions]::RemoveEmptyEntries)){$o,$r=$item.Split(':');$map[$o]=$r}
    $expected[$name]=$map
}
Set-Matrix PS_Lead_Management 'Lead:CRE'
Set-Matrix PS_Opportunity_Management 'Opportunity:CRE Opportunity__c:CRE Opportunity_Contact__c:CRE Opportunity_Teams__c:CRED'
Set-Matrix PS_Business_Detail_Management 'Business_Detail__c:CRE'
Set-Matrix PS_Invoice_Billing_Management 'Invoice__c:R Billing_Information__c:R Billing_Line_Item__c:R Contact_Billing_Line_Item__c:CRE Debit_Credit_Note__c:R Payment__c:R Account:R'
Set-Matrix PS_Journey_Event_Management 'Journey__c:CRE Event__c:CRE Event_Account_Association__c:CRE Event_Lead__c:CRE Event_Team__c:CRE Event_Contact__c:CRE Expense_Item__c:CRED Account:R'
Set-Matrix PS_Account_Contact_Management 'Account:RE Account_Team__c:R Contact:CRE Other_Address__c:CRE'
Set-Matrix PS_Quote_Management 'Quote__c:CRE Quote_Line_Item__c:CRE Opportunity__c:R'
Set-Matrix PS_Case_FieldCommon 'Case__c:CRE Account:R'
Set-Matrix PS_Contract_FieldCommon 'Contract__c:CRE'
Set-Matrix PS_Reference_Data_ReadOnly 'Branch_Master__c:R Commandment_Master__c:R Group_State_Master__c:R Price_Master__c:R Zone_Matrix__c:R SpotFire_Group__c:R User_Branch_Mapping__c:R PropelI_BDM_Mapping__c:R Renewal_SFX_RC_Mapping__c:R Sales_Data__c:R Account:R'
Set-Matrix PS_Field_Misc 'Document:CRE Idea:CR Waybill_Details__c:CRE Product_Packaging__c:CRE Release__c:RV Account:R Case__c:R Opportunity__c:R'
Set-Matrix PS_BDM_Delta 'Announcement__c:RV Campaign_Team__c:R Campaign__c:CRE GST_Validation_Event__e:CR Integration_Transaction__c:CRE PropelI_Active_Code__c:RV Target__c:R'
Set-Matrix PS_AreaMgr_Delta 'Announcement__c:R Campaign_Team__c:CRE Campaign__c:CRE GST_Validation_Event__e:CR Integration_Transaction__c:CR Target__c:RE'
Set-Matrix PS_RegMgr_Delta 'Announcement__c:R Campaign_Team__c:R Campaign__c:CR Integration_Transaction__c:CRE Target__c:RE'
Set-Matrix PS_Claim_Management 'Billing_Information__c:R Billing_Line_Item__c:R Business_Detail__c:CRE Campaign_Team__c:R Campaign__c:R Commandment_Master__c:R Event_Lead__c:CRE Event_Team__c:CRE Event__c:CRE Expense_Item__c:CRED Group_State_Master__c:R Journey__c:CRE Other_Address__c:CRE Price_Master__c:R SpotFire_Group__c:R Target__c:R Zone_Matrix__c:R Branch_Master__c:R Case__c:CREV Invoice__c:R Lead__c:CRE Opportunity__c:CRE Product_Packaging__c:CRE Quote_Line_Item__c:CRE Quote__c:CRE Sales_Data__c:R User_Branch_Mapping__c:R Release__c:RV Renewal_SFX_RC_Mapping__c:R Integration_Transaction__c:CRE Event_Contact__c:CRE Contact_Billing_Line_Item__c:CRE Contract__c:CRE Account:REV Contact:CRE Document:CRE Idea:CR Account_Team__c:R Debit_Credit_Note__c:R Payment__c:R Waybill_Details__c:CRE'
Copy-Matrix PS_Campaign_Management PS_Claim_Management @() 'Campaign_Team__c:CRE Campaign__c:CREV Case__c:CRE Campaign_Lead__c:R'
Copy-Matrix PS_CCD_Management PS_Claim_Management @() 'Billing_Information__c:RV Billing_Line_Item__c:RV Event__c:CREV Case__c:CRE Invoice__c:RV Opportunity__c:CREDVM Integration_Transaction__c:CR Account:REDVM Contact:CREV Account_Team__c:REV PropelI_BDM_Mapping__c:RV Announcement__c:RV'
Copy-Matrix PS_Revenue_Management PS_Claim_Management @() 'Invoice__c:RV Opportunity__c:CREV PropelI_BDM_Mapping__c:R Announcement__c:RV Opportunity_Contact__c:REV'
Copy-Matrix PS_CentralQuotation_Credit PS_Claim_Management @() 'Case__c:CRE Account:RE Contact:CREV Opportunity_Contact__c:CREV Opportunity_Teams__c:CRE'
Copy-Matrix PS_CentralQuotation_Retail PS_CentralQuotation_Credit @('Price_Master__c','Opportunity_Contact__c','Opportunity_Teams__c') 'Lead__c:CREV'
Copy-Matrix PS_Portfolio_Management PS_Claim_Management @('Product_Packaging__c','Quote_Line_Item__c') 'Billing_Information__c:CRV Billing_Line_Item__c:CRV Campaign__c:CREV Event__c:CREV Journey__c:CREV Target__c:CRE Branch_Master__c:RV Case__c:CRE Quote__c:R Account:CREDVM Account_Team__c:CREDVM PropelI_BDM_Mapping__c:RV Announcement__c:RV PropelI_Active_Code__c:RV'
Copy-Matrix PS_Onboarding_Management PS_Claim_Management @('Product_Packaging__c','Quote_Line_Item__c') 'Target__c:CRE Quote__c:R Contact:CREDVM Account_Team__c:CRED PropelI_BDM_Mapping__c:RV Opportunity_Contact__c:CRE'
Set-Matrix PS_Contact_ReadOnly 'Opportunity__c:R Account:R Business_Detail__c:R Contact:R'
Set-Matrix PS_Conveyance_Finance 'Event_Team__c:R Event__c:CREDVM Expense_Item__c:CREDVM Journey__c:CREDVM Release__c:RV Integration_Transaction__c:CRE Event_Contact__c:CRE Contract__c:CRE Contact:CRED Document:CRED Idea:CR Announcement__c:RV Fusion_Invoice__c:CRE Line_and_Distribution__c:R'
Set-Matrix PS_Target_Management 'Billing_Information__c:R Billing_Line_Item__c:R Business_Detail__c:R Campaign_Team__c:R Campaign__c:R Commandment_Master__c:R Event_Lead__c:R Event_Team__c:CRE Event__c:CRE Expense_Item__c:CRED Group_State_Master__c:R Journey__c:CRE Price_Master__c:R SpotFire_Group__c:R Target__c:CREDVM Zone_Matrix__c:R Opportunity__c:R Quote_Line_Item__c:CRE Quote__c:R Release__c:RV Renewal_SFX_RC_Mapping__c:R Integration_Transaction__c:CRE Event_Contact__c:CRE Contact_Billing_Line_Item__c:CRE Contract__c:CRE Account:CRED Contact:CRED Document:CRED Idea:CR Individual:CRED'
$issues=[Collections.Generic.List[object]]::new()
$objectRows=[Collections.Generic.List[object]]::new()
$summary=[Collections.Generic.List[object]]::new()
function Issue($severity,$set,$kind,$component,$detail){$issues.Add([pscustomobject]@{Severity=$severity;PermissionSet=$set;Check=$kind;Component=$component;Detail=$detail})}
$fieldCache=@{};$rtCache=@{}
function Fields($obj){
    if(-not $fieldCache.ContainsKey($obj)){
        $map=@{};$path=Join-Path $base "objects/$obj/fields"
        if(Test-Path $path){foreach($file in Get-ChildItem $path -Filter '*.xml'){[xml]$d=[IO.File]::ReadAllText($file.FullName);$map[[string]$d.CustomField.fullName]=$d.CustomField}}
        $fieldCache[$obj]=$map
    }
    return $fieldCache[$obj]
}
function Records($obj){
    if(-not $rtCache.ContainsKey($obj)){
        $records=@();$path=Join-Path $base "objects/$obj/recordTypes"
        if(Test-Path $path){foreach($file in Get-ChildItem $path -Filter '*.xml'){[xml]$d=[IO.File]::ReadAllText($file.FullName);if($d.RecordType.active -eq 'true'){$records+="$obj.$($d.RecordType.fullName)"}}}
        $rtCache[$obj]=$records
    }
    return $rtCache[$obj]
}
$standardTabs=@{};$standardFields=@{}
[xml]$admin=[IO.File]::ReadAllText((Join-Path $base 'profiles/Admin.profile-meta.xml'))
foreach($tab in $admin.Profile.tabVisibilities){if($tab.tab -like 'standard-*'){$standardTabs[$tab.tab.Substring(9)]=$tab.tab}}
$standardTabs['Document']='standard-Document'
foreach($f in $admin.Profile.fieldPermissions){$o,$fn=$f.field.Split('.');if($o -notlike '*__c'){$standardFields[$f.field]=$true}}
$files=@(Get-ChildItem (Join-Path $base 'permissionsets') -Filter 'PS_*.permissionset-meta.xml')
$files+=@(Get-ChildItem (Join-Path $base 'permissionsets') -Filter 'Contract_Management_Team_Read_*.permissionset-meta.xml')
$flagMap=[ordered]@{allowCreate='C';allowRead='R';allowEdit='E';allowDelete='D';viewAllRecords='V';modifyAllRecords='M'}
foreach($file in $files){
    $name=$file.Name.Replace('.permissionset-meta.xml','');$before=[IO.File]::ReadAllText($file.FullName);[xml]$doc=$before;$p=$doc.PermissionSet
    $known=$expected.ContainsKey($name);$objects=@{};$changed=$false;$tabChanges=0
    foreach($op in $p.objectPermissions){if($objects.ContainsKey([string]$op.object)){Issue ERROR $name DuplicateObject $op.object 'Duplicate object entry'};$objects[[string]$op.object]=$op}
    if($known){
        foreach($o in $expected[$name].Keys){
            if(-not $objects.ContainsKey($o)){Issue ERROR $name MissingObject $o $expected[$name][$o];continue}
            $op=$objects[$o];$r=$expected[$name][$o]
            foreach($flag in $flagMap.Keys){$want=$r.Contains($flagMap[$flag]).ToString().ToLowerInvariant();if($op.$flag -ne $want){Issue ERROR $name ObjectPermission "$o.$flag" "Expected $want; actual $($op.$flag)";if($Fix){$op.$flag=$want;$changed=$true}}}
        }
        foreach($o in $objects.Keys){if(-not $expected[$name].ContainsKey($o)){Issue ERROR $name ExtraObject $o 'Not in approved matrix or explicit dependency additions'}}
        if($p.license){Issue ERROR $name License $p.license 'Expected no license restriction'}
    }else{Issue INFO $name MatrixNotProvided '' 'No user object-access table in this conversation; existing object rights preserved'}
    if($name -eq 'PS_Journey_Auditor' -and $JourneyAccess -eq 'Edit'){$objects['Journey__c'].allowEdit='true';$changed=$true}
    $fieldEntries=@{}
    foreach($entry in $p.fieldPermissions){
        $full=[string]$entry.field;$o,$fn=$full.Split('.')
        if($fieldEntries.ContainsKey($full)){Issue ERROR $name DuplicateField $full 'Duplicate field entry'};$fieldEntries[$full]=$entry
        if(-not $objects.ContainsKey($o)){Issue ERROR $name FieldWithoutObject $full 'No object permission entry';continue}
        if($o -like '*__e'){Issue WARNING $name EventFLS $full 'Platform event field-level security does not apply';continue}
        $map=Fields $o;$meta=$map[$fn]
        $readOnly=($meta -and ($meta.formula -or $meta.type -in @('Summary','AutoNumber'))) -or $full -in @('Lead.LastTransferDate','Opportunity.ExpectedRevenue','Individual.MasterRecordId')
        if(-not $meta -and -not $standardFields.ContainsKey($full)){Issue ERROR $name MissingFieldMetadata $full 'Not found in field metadata or Admin field permissions'}
        if($meta -and ($meta.required -eq 'true' -or $meta.type -eq 'MasterDetail')){Issue ERROR $name NonPermissionableField $full 'Required/master-detail field should not have FLS entry'}
        if($readOnly -and $entry.editable -eq 'true'){Issue ERROR $name CalculatedFieldEdit $full 'Calculated/system field should be read-only';if($Fix -and $known){$entry.editable='false';$changed=$true}}
        if($known){
            $wantedEdit=($objects[$o].allowEdit -eq 'true' -and -not $readOnly).ToString().ToLowerInvariant()
            # Dependency-only object grants intentionally have no new FLS added.
            if($entry.editable -ne $wantedEdit -or $entry.readable -ne 'true'){Issue ERROR $name FieldAccess $full "Expected readable=true editable=$wantedEdit; actual readable=$($entry.readable) editable=$($entry.editable)";if($Fix){$entry.editable=$wantedEdit;$entry.readable='true';$changed=$true}}
        }elseif($entry.editable -eq 'true' -and $objects[$o].allowEdit -ne 'true'){
            Issue WARNING $name FieldEditWithoutObjectEdit $full 'Field Edit does not grant object Edit; cannot edit existing records through this set alone'
            if($Fix -and $name -eq 'PS_Journey_Auditor' -and $o -eq 'Journey__c' -and $JourneyAccess -eq 'ReadOnly'){$entry.editable='false';$changed=$true}
        }
    }
    foreach($o in $objects.Keys){
        $op=$objects[$o];$r='';foreach($flag in $flagMap.Keys){if($op.$flag -eq 'true'){$r+=$flagMap[$flag]}}
        $objectRows.Add([pscustomobject]@{PermissionSet=$name;Object=$o;Actual=$r;Expected=if($known){$expected[$name][$o]}else{'NOT PROVIDED'};Create=$op.allowCreate;Read=$op.allowRead;Edit=$op.allowEdit;Delete=$op.allowDelete;ViewAll=$op.viewAllRecords;ModifyAll=$op.modifyAllRecords})
        if($op.modifyAllRecords -eq 'true' -and ($op.allowRead -ne 'true' -or $op.allowEdit -ne 'true' -or $op.allowDelete -ne 'true' -or $op.viewAllRecords -ne 'true')){Issue ERROR $name ModifyAllPrerequisites $o 'Missing Read/Edit/Delete/View All'}
        if($op.allowRead -ne 'true'){Issue ERROR $name ReadPrerequisite $o 'Expected Read for object grants in scope'}
        $fm=Fields $o
        foreach($meta in $fm.Values){
            if($meta.type -eq 'MasterDetail'){
                $parent=[string]$meta.referenceTo
                if(-not $objects.ContainsKey($parent) -or $objects[$parent].allowRead -ne 'true'){Issue ERROR $name ParentRead $o "Requires Read $parent"}
                elseif($meta.writeRequiresMasterRead -eq 'false' -and ($op.allowCreate -eq 'true' -or $op.allowEdit -eq 'true' -or $op.allowDelete -eq 'true') -and $objects[$parent].allowEdit -ne 'true'){Issue WARNING $name ParentWriteSharing $o "Master-detail requires write sharing to parent records ($parent); parent Edit is not granted by this set. Check effective user access in org; do not broaden the approved matrix automatically."}
            }
        }
        $hasFls=@($fieldEntries.Keys | Where-Object { $_.StartsWith($o+'.') }).Count -gt 0
        if($known -and $hasFls -and $o -notlike '*__e'){
            foreach($fn in $fm.Keys){$meta=$fm[$fn];$full="$o.$fn";if($meta.required -eq 'true' -or $meta.type -eq 'MasterDetail'){continue};if(($fn -like '*__c' -or $standardFields.ContainsKey($full)) -and -not $fieldEntries.ContainsKey($full)){Issue ERROR $name MissingFieldAccess $full 'Permissionable local field missing'}}
            foreach($rt in (Records $o)){if($rt -notin $p.recordTypeVisibilities.recordType){Issue ERROR $name MissingRecordType $rt 'Existing record type absent'}}
        }
        $tabName=$null
        if(Test-Path (Join-Path $base "tabs/$o.tab-meta.xml")){$tabName=$o}elseif($standardTabs.ContainsKey($o)){$tabName=$standardTabs[$o]}
        if($tabName -and $tabName -notin $p.tabSettings.tab){
            Issue ERROR $name MissingTab $tabName 'Object has an existing tab; requested Visible setting missing'
            if($Fix){$node=$doc.CreateElement('tabSettings',$p.NamespaceURI);foreach($pair in @(@('tab',$tabName),@('visibility','Visible'))){$child=$doc.CreateElement($pair[0],$p.NamespaceURI);$child.InnerText=$pair[1];[void]$node.AppendChild($child)};$anchor=$p.ChildNodes | Where-Object LocalName -eq 'userPermissions' | Select-Object -First 1;if($anchor){[void]$p.InsertBefore($node,$anchor)}else{[void]$p.AppendChild($node)};$changed=$true;$tabChanges++}
        }
    }
    foreach($entry in $p.tabSettings){
        if($entry.visibility -ne 'Visible'){Issue ERROR $name TabVisibility $entry.tab "Expected Visible; actual $($entry.visibility)";if($Fix){$entry.visibility='Visible';$changed=$true;$tabChanges++}}
        if($entry.tab -notlike 'standard-*' -and -not(Test-Path (Join-Path $base "tabs/$($entry.tab).tab-meta.xml"))){Issue ERROR $name MissingTabMetadata $entry.tab 'Tab does not exist locally'}
    }
    foreach($entry in $p.recordTypeVisibilities){$o,$rt=$entry.recordType.Split('.');if(-not(Test-Path (Join-Path $base "objects/$o/recordTypes/$rt.recordType-meta.xml"))){Issue ERROR $name RecordTypeReference $entry.recordType 'Record type metadata absent'};if($entry.visible -ne 'true' -and $known){Issue ERROR $name RecordTypeVisibility $entry.recordType 'Expected visible=true'}}
    if($Fix -and $changed){
        $backup=Join-Path $out 'before';[void][IO.Directory]::CreateDirectory($backup);$backupFile=Join-Path $backup $file.Name;if(-not(Test-Path $backupFile)){[IO.File]::WriteAllText($backupFile,$before,[Text.UTF8Encoding]::new($false))}
        $settings=[Xml.XmlWriterSettings]::new();$settings.Indent=$true;$settings.IndentChars='    ';$settings.Encoding=[Text.UTF8Encoding]::new($false);$settings.NewLineChars="`n";$writer=[Xml.XmlWriter]::Create($file.FullName,$settings);try{$doc.Save($writer)}finally{$writer.Dispose()}
    }
    $summary.Add([pscustomobject]@{PermissionSet=$name;MatrixChecked=$known;Objects=$objects.Count;Fields=$fieldEntries.Count;Tabs=@($p.tabSettings).Count;TabChanges=$tabChanges;Changed=$changed})
}
$common='PS_Lead_Management','PS_Opportunity_Management','PS_Business_Detail_Management','PS_Invoice_Billing_Management','PS_Journey_Event_Management','PS_Account_Contact_Management','PS_Quote_Management','PS_Case_FieldCommon','PS_Contract_FieldCommon','PS_Reference_Data_ReadOnly','PS_Field_Misc'
$groups=[ordered]@{PSG_TerritoryManager=($common+@('PS_BDM_Delta'));PSG_AreaManager=($common+@('PS_AreaMgr_Delta'));PSG_RegionalManager=($common+@('PS_RegMgr_Delta'));PSG_Contract_ReadOnly=@('Contract_Management_Team_Read_Only');PSG_Contract_ReadWrite=@('Contract_Management_Team_Read_Write');PSG_CCD_Team=@('PS_CCD_Management');PSG_Revenue_Team=@('PS_Revenue_Management');PSG_Claim_Team=@('PS_Claim_Management');PSG_Conveyance_Team=@('PS_Conveyance_Finance');PSG_Campaign_Team=@('PS_Campaign_Management');PSG_Portfolio_Management=@('PS_Portfolio_Management');PSG_Target_Team=@('PS_Target_Management');PSG_Onboarding_Team=@('PS_Onboarding_Management');PSG_CQ_Credit=@('PS_CentralQuotation_Credit');PSG_CQ_Retail=@('PS_CentralQuotation_Retail');PSG_Contact_ReadOnly=@('PS_Contact_ReadOnly');PSG_Journey_Auditor=@('PS_Journey_Auditor')}
foreach($g in $groups.Keys){
    $path=Join-Path $base "permissionsetgroups/$g.permissionsetgroup-meta.xml"
    if(-not(Test-Path $path)){Issue ERROR $g MissingGroup $g 'Group metadata absent';continue}
    [xml]$gd=[IO.File]::ReadAllText($path);$gp=$gd.PermissionSetGroup
    if(@($gp.permissionSets).Count -ne @($groups[$g]).Count -or (Compare-Object @($groups[$g]) @($gp.permissionSets))){Issue ERROR $g GroupMembership $g 'Does not match requested membership'}
    foreach($ps in $gp.permissionSets){if(-not(Test-Path (Join-Path $base "permissionsets/$ps.permissionset-meta.xml"))){Issue ERROR $g MissingPermissionSet $ps 'Referenced permission set absent locally'}}
    foreach($muted in $gp.mutingPermissionSets){if($muted){$mf=Get-ChildItem $base -Recurse -File -Filter "$muted.*" | Select-Object -First 1;if(-not $mf){Issue WARNING $g MissingMutingMetadata $muted 'Existing muting reference preserved; effective access cannot be verified locally'}}}
}
$suffix=if($Fix){'changes'}else{'results'}
$issues | Export-Csv (Join-Path $out "$suffix.csv") -NoTypeInformation
$summary | Export-Csv (Join-Path $out "summary-$suffix.csv") -NoTypeInformation
$objectRows | Sort-Object PermissionSet,Object | Export-Csv (Join-Path $out 'object-access.csv') -NoTypeInformation
[pscustomobject]@{Mode=$suffix;PermissionSets=$files.Count;Matrices=$expected.Count;Objects=$objectRows.Count;Fields=($summary | Measure-Object Fields -Sum).Sum;Tabs=($summary | Measure-Object Tabs -Sum).Sum;Changed=@($summary | Where-Object Changed).Count;Errors=@($issues | Where-Object Severity -eq ERROR).Count;Warnings=@($issues | Where-Object Severity -eq WARNING).Count} | ConvertTo-Json
$issues | Group-Object Severity,Check | Select-Object Name,Count | Format-Table -AutoSize
if(-not $Fix -and @($issues | Where-Object Severity -eq ERROR).Count -gt 0){exit 1}
