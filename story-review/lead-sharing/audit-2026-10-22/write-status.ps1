$ErrorActionPreference='Stop'
$out=$PSScriptRoot
$review=(Resolve-Path "$out/..").Path
$root=(Resolve-Path "$review/../..").Path
$base="$root/force-app/main/default"
$utf8=New-Object System.Text.UTF8Encoding($false)
function Save($file,$lines){[IO.File]::WriteAllText("$out/$file",($lines -join "`r`n"),$utf8)}
$groups=Import-Csv "$out/group-status.csv"
$members=Import-Csv "$out/regional-memberships.csv"
$rules=Import-Csv "$out/sharing-rules.csv"
$deployment=(Get-Content "$out/latest-deployment.json" -Raw | ConvertFrom-Json).result
$org=(Get-Content "$out/organization.json" -Raw | ConvertFrom-Json).result.records[0]
$owd=(Get-Content "$out/lead-owd.json" -Raw | ConvertFrom-Json).result.records[0]
$tabs=(Get-Content "$out/app-tabs-live.json" -Raw | ConvertFrom-Json).result.records
if($deployment.checkOnly -or !$deployment.success -or $deployment.numberComponentsDeployed -ne 54){throw 'Deployment evidence differs from report assumptions'}
if(@($members | Where-Object Status -eq 'VERIFIED LIVE').Count -ne 72 -or @($rules | Where-Object Status -eq 'MISMATCH').Count -gt 0){throw 'Membership/rule mismatch requires revised report'}
$requiredFieldResult=Get-Content "$out/required-fields-live.json" -Raw | ConvertFrom-Json
if($requiredFieldResult.status -ne 0 -or !$requiredFieldResult.result.done){throw 'Required-field live query failed'}
foreach($f in @('Assignment_Evaluated__c','Pincode_Lookup_Status__c','GST_Status__c')){if($f -cin @($requiredFieldResult.result.records.QualifiedApiName)){throw 'Field findings changed'}}
$status=@(
@('C-01','Lead persona object access','PARTIAL','PS_Lead_Management has live Read/Create/Edit=true; Delete/ViewAll/ModifyAll=false. Local PSG_AreaManager, PSG_RegionalManager, PSG_TerritoryManager include it. Full persona roster, user assignments, muting and other permission grants not verified.','Dev 5','lead-object-permissions.json; permission-set-groups.csv'),
@('C-01 FLS','System fields read-only','MISSING DEPENDENCY','Assignment_Evaluated__c, Pincode_Lookup_Status__c and GST_Status__c are absent from standard Lead in local files and live EntityParticle query. Required read-only FLS cannot be satisfied for these exact fields. Confirm revised names if the design changed.','UST1 / Dev 5','required-fields-live.json; fields.csv'),
@('C-02','App and Lead tab','VERIFIED LIVE','safexpress2_0 exists and live navigation contains Lead. Retrieved app activates credit_and_retail for Lead on Large and Small forms. PS_Lead_Management locally has standard-Lead visibility Visible.','Stream C / Dev 5','lead-app.json; app-tabs-live.json; applications/safexpress2_0.app-meta.xml'),
@('C-03','Internal and external Lead OWD','VERIFIED LIVE',"Internal=$($owd.InternalSharingModel); External=$($owd.ExternalSharingModel).",'Stream C','lead-owd.json'),
@('C-04','18 regional groups and 72 direct Roles','VERIFIED LIVE','All 18 exact groups exist; all hierarchy flags true; every expected Role DeveloperName resolves to one live UserRole and one Group of Type=Role; all 72 GroupMember links match, four per group; zero extra members.','Stream C','groups.json; roles.json; role-groups.json; members.json; regional-memberships.csv'),
@('C-05','Safexperience group initially empty','VERIFIED LIVE','Safexperience_Team label is Safexperience Team, hierarchy=true, zero direct members. This satisfies the initial setup; no Safexperience user access is granted through the empty group yet.','Stream C / business owner','group-status.csv'),
@('C-06','34 sharing rules','VERIFIED RETRIEVED XML + DEPLOYMENT','18 regional + 14 VH + 1 Alliance + 1 Safexperience. All 34 exactly match the approved field/value/filter/group/access/owner-scope plan; successful non-check-only deployment includes all 34. Runtime recalculation/access not tested.','Stream C','sharing-rules.csv; latest-deployment.json'),
@('VH recipients','Existing 14 VH groups reused','CONFIGURATION EXISTS; ACCESS GAP','All 14 groups exist live with hierarchy=true but all have zero direct members. Therefore no VH users gain access through those groups. No membership assignments were invented or changed.','VH group/business owner','group-status.csv; members.json'),
@('Alliance recipients','Existing Alliance group','PARTIAL','Alliance_Partner_Management exists with hierarchy=true and one direct member. Business suitability and effective Read-only access remain untested; additive grants can give Edit.','Business owner / UST4 access review','groups.json; members.json'),
@('AC2 / UST8','Creation page fields and required flags','PARTIAL','credit_and_retail includes Name, Company, MobilePhone, Email, LeadSource and compound Address. Email/MobilePhone/Address/LeadSource have uiBehavior=none; not explicit Dynamic Forms required flags. Creation-page behavior, profile layout assignments and the complete UST1 4.6 list are not established.','UST8 / UST1','dynamic-form-fields.csv; lead-layout-fields.csv'),
@('AC3 / UST1','Mandatory server-side validation','PARTIAL / NAMING DEVIATION','Exact Lead_Pincode_Required and Lead_Contact_Address_Required names are absent. Live Validate_Pincode and Lead_Core_Mandatory_Fields are active. Retrieved formulas enforce pincode/contact-address conditions with bypass/routing exceptions; confirm equivalence and messages against UST1.','UST1 / BA','validation-rules-live.json; validation-rules.csv'),
@('AC4','Manual owner=creator','CONFIGURATION CONSISTENT; TEST REQUIRED','No live ApexTrigger on standard Lead; retrieved Lead assignment-rule container empty; no active retrieved Lead record-triggered Flow. Manual-create owner behavior has not been tested as personas.','UST4 / QA','lead-triggers.json; lead-triggered-flows.csv; assignmentRules/Lead.assignmentRules-meta.xml'),
@('UST4','Central Desk/Web/Case routing and reassignment','NOT VERIFIED','Assign_to_Central_Desk__c exists. CaseContactHelper creates Lead with the checkbox=true, but inspected code does not set OwnerId there. No retrieved standard-Lead routing implementation was established by the scoped search. Confirm UST4 merge and run routing/ownership tests.','UST4','classes/CaseContactHelper.cls:214; lead-triggered-flows.csv'),
@('Record types','No custom Lead record types','VERIFIED LIVE','Live RecordType query returned zero standard Lead record-type records; consistent with no custom record types. Master behavior remains standard.','Design','lead-record-types.json'),
@('Post-deployment','Sharing recalculation and T3-01 to T3-17','NOT TESTED','No records created/updated, user impersonation, access checks against approved test users/records or recalculation-job confirmation performed in this read-only audit.','QA / UST4 / Dev 5','test-status.csv'),
@('Parked decisions','Corporate heads, Finance, persona roster','OPEN DESIGN ITEMS','LLD 4.7 and TDD open points 8/9/10 are not designed here. No corporate/finance group memberships or temporary regional User assignments were inferred.','BA / Architect','User-supplied LLD')
)
$rows=@();foreach($s in $status){$rows += [pscustomobject]@{ID=$s[0];Requirement=$s[1];Status=$s[2];Finding=$s[3];Owner=$s[4];Evidence=$s[5]}};$rows | Export-Csv "$out/requirement-status.csv" -NoTypeInformation
$tests=@(
@('T3-01','Persona can open New Lead','Permission metadata partly confirmed; test every approved persona'),
@('T3-02','No Lead Create prevents creation','Requires a restricted test persona'),
@('T3-03','Creation fields from UST1 are present','Page/layout evidence inspected; UST1 full list and actual New form need review'),
@('T3-04','Missing pincode/contact/address rejected','Active alternate-named validation rules found; test exceptions and messages'),
@('T3-05','Manual creation owner is creator','Configuration consistent; runtime not run'),
@('T3-06','Central Desk checkbox routes owner','UST4 merge/runtime evidence needed'),
@('T3-07','AM and own RM see Lead','Use approved users after recalculation'),
@('T3-08','Other-region RM cannot see Lead','Account for approved GJT-to-MUM hierarchy and other grants'),
@('T3-09','DLI group Edit, no Area Manager membership','Four exact Roles verified; actual record access still needs test'),
@('T3-10','AM assigns Lead to TM','UST4/runtime test needed'),
@('T3-11','AM/RM retain visibility after TM assignment','UST4/runtime test needed'),
@('T3-12','Pincode change does not change owner','UST4/runtime test needed'),
@('T3-13','Central Desk queue and ancestors see Lead','Queue/routing/effective-access test needed'),
@('T3-14','Creator loses access outside hierarchy','Test with no other additive access grants'),
@('T3-15','Safexperience source-based Edit','Initially empty by design; add separately approved test recipient before test; use Website per user confirmation'),
@('T3-16','VH vertical Edit','Blocked by 14 empty VH groups; use approved members and exact retained legacy values'),
@('T3-17','Alliance vertical Read only','One group member exists; verify identity, object access and no overlapping Edit grant')
)
$tr=@();foreach($t in $tests){$tr += [pscustomobject]@{Test=$t[0];Scenario=$t[1];ExecutionStatus='NOT EXECUTED IN THIS READ-ONLY AUDIT';PrerequisiteOrFinding=$t[2]}};$tr | Export-Csv "$out/test-status.csv" -NoTypeInformation
[xml]$manifest=Get-Content "$review/deployment-payload/package.xml"
$success=@($deployment.details.componentSuccesses | Where-Object componentType)
$componentRows=@();foreach($type in $manifest.Package.types){foreach($name in $type.members){$match=@($success | Where-Object {$_.componentType -ceq $type.name -and $_.fullName -ceq $name});if($match.Count -ne 1){throw "Unmatched manifest component $name"};$relative=[string]$match[0].fileName -replace '^zip/','';$componentRows += [pscustomobject]@{Type=[string]$type.name;Component=[string]$name;DeploymentId=$deployment.id;Status='SUCCEEDED; checkOnly=false';DeploymentFile=[string]$match[0].fileName;LocalPayloadFile=(Join-Path "$review/deployment-payload" $relative)}}}
$componentRows | Export-Csv "$out/deployed-components.csv" -NoTypeInformation
$componentText=@('# All 54 deployed package components','','Confirmed from successful non-check-only deployment 0AfC1000009voVzKAI. This is deployment evidence; current group/OWD state and retrieved rules are separately audited.','','| Type | Component | Full local XML file | Status |','| --- | --- | --- | --- |');foreach($c in $componentRows){$componentText+="| $($c.Type) | $($c.Component) | $($c.LocalPayloadFile) | $($c.Status) |"};Save 'deployed-components.md' $componentText
$report=@('# Lead Creation and Sharing Model - status audit, 2026-10-22','',
'**Verdict: Stream C configuration and regional memberships are complete under the confirmed design. The full LLD is not ready for final acceptance because dependencies and runtime tests remain open.**','',
"Org: Dev1 / $($org.Name) / $($org.Id), sandbox=$($org.IsSandbox).",
"Deployment: $($deployment.id), status=$($deployment.status), success=$($deployment.success), checkOnly=$($deployment.checkOnly), components=$($deployment.numberComponentsDeployed), completed=$($deployment.completedDate) (2026-10-21 17:35:20 India time).",
'This supersedes the older check-only finding. The package was actually deployed. No deployment, membership change, data DML or metadata retrieval was performed by this audit.','',
'## Design used for comparison',
'The attached LLD is the baseline, with the user''s earlier explicit confirmations: BJO uses BIHAR - JHARKHAND - ODISHA; KRL uses KERALAM; JKH uses JK - HP - LADAKH; Safexperience uses Website OR Safexperience Centre; retain exact inactive legacy VH criteria; app is safexpress2_0; retain GJT hierarchy and includeRecordsOwnedByAll=false. The pasted LLD still shows the older Region/source/app names and should be reconciled in documentation. Two LeadSource equals conditions with Boolean 1 OR 2 have the approved either-value semantics.','',
'## Requirement-by-requirement status','','| ID | Requirement | Status | Finding | Owner / evidence |','| --- | --- | --- | --- | --- |')
foreach($r in $rows){$report+="| $($r.ID) | $($r.Requirement) | $($r.Status) | $($r.Finding) | $($r.Owner); $($r.Evidence) |"}
$report+=@('','## Regional membership results','','| Group | Direct members | Exact expected Role members verified | Extra members | Hierarchy access | Status |','| --- | --- | --- | --- | --- | --- |')
foreach($g in @($groups | Where-Object Group -like 'SG_RGN_*' | Sort-Object Group)){$report+="| $($g.Group) | $($g.DirectMembers) | $($g.ExpectedRolesVerified) | $($g.ExtraMembersForRegionalGroup) | $($g.Hierarchy) | $($g.Status) |"}
$report+=@('','The 72 per-role rows, live UserRole IDs, Type=Role group IDs and GroupMember IDs are in regional-memberships.csv. No RoleAndSubordinates or direct User member is present in the 18 groups. Existing GJT hierarchy is deliberately retained per user direction.','',
'## Highest-priority remaining checks','',
'1. Obtain approved VH recipient assignments. All 14 VH groups have zero direct members, so their rules cannot currently give any VH user access. This is a reused-group business dependency, not a request to change recipients automatically.',
'2. UST1/Dev 5 must resolve the three absent exact system fields (Assignment_Evaluated__c, Pincode_Lookup_Status__c, GST_Status__c) or confirm replacement API names. Verify read-only FLS after the field contract is settled.',
'3. UST8 must confirm the actual New Lead form, profile layout assignment and required flags. In the activated record page, Email, MobilePhone, LeadSource and compound Address have uiBehavior=none. The Credit and retail layout marks these Edit; required fields such as Company/Region/Vertical can also be enforced by standard/field metadata. Do not infer that the existence of a record-page component proves the New dialog is correct.',
'4. UST1/BA must accept the alternative validation rule names and intentional exceptions. Lead_Core_Mandatory_Fields skips its contact/address checks for Skip_Validation_Rule, IsVRBypassed__c, Converted status, Website/Social Media, and case-linked records. Validate_Pincode handles blank values unless bypassed and rejects nonblank non-six-digit values. These are not blanket mandatory checks in every scenario. No UST1 source document or exact required message contract was supplied.',
'5. Dev 5 must confirm the persona roster and assignments. PS_Lead_Management is correct live; the three management PSGs include it locally. Other task-specific PSGs do not automatically imply persona scope. Effective access can also come from profiles, other permission sets, muting/session activation and View All/Modify All. No user-level acceptance is claimed.',
'6. UST4 must confirm routing/ownership behavior and run T3-06 and T3-10 to T3-14. The inspected CaseContactHelper sets the Central Desk checkbox while creating a standard Lead, but does not set OwnerId in that block. The retrieved Lead assignment-rule container is empty and there is no live standard Lead Apex trigger. The scoped evidence does not prove the routing dependency is delivered.',
'7. Verify sharing recalculation and execute all T3-01 to T3-17 with approved users and records. T3-15 needs later Safexperience membership; its current empty state is correct initial configuration. Alliance has one direct member but Read-only behavior must be tested against overlapping grants.',
'8. Corporate-head/Finance visibility, temporary RM coverage and the final persona roster remain parked design items. No extra membership or permission was assumed.','',
'## Evidence and scope',
'Live evidence: organization/groups/members/roles/role-groups/lead-owd/lead-object-permissions/lead-record-types/lead-triggers/lead-app/app-tabs-live/required-fields-live/validation-rules-live JSON files and latest-deployment.json. Metadata evidence comes from the user-provided retrieved force-app files; the audit did not retrieve or overwrite source metadata. Full permission-set, PSG, field, Dynamic Forms, layout, validation-rule and standard Lead-triggered-Flow inventories are provided as CSV files in this folder.',
'Sharing rules were checked semantically against all 34 approved definitions and the 14 retrieved legacy VH rules, including field names, operators, exact values, implicit/explicit AND, OR, target groups, access and owner scope. The standard Lead container has 34 criteria rules and no Type__c criterion. No live metadata read/retrieve was used to re-fetch rule definitions after the user''s retrieval.',
'deployed-components.md/csv lists every manifest component and full local payload file path. There are 19 Group files, one Lead object file, one sharing-rule container and package.xml: 22 physical package files representing 54 metadata components. Permission sets, fields, validation rules, pages, roles, Apex and the already-correct app were not included in that isolated deployment package.',
'No runtime test or org mutation was carried out. The supplied story text alone cannot establish completion of UST1 4.6, UST4 routing or UST8/Dev 5 acceptance.'
)
Save 'status-report.md' $report
$record=Import-Csv "$review/deployment-record.csv"
if(@($record | Where-Object {$_.ActualDeploymentId -ceq $deployment.id}).Count -eq 0){$record+= [pscustomobject]@{Environment='DEV';Step='Complete 54-component deployment verified read-only';Status='SUCCEEDED - DEPLOYED';ActualOrgId=$org.Id;ActualDeploymentId=$deployment.id;PerformedAt=$deployment.completedDate;ArtifactSHA256='';EvidencePath="$out/latest-deployment.json";Notes='User-run actual deployment verified; 72 exact regional Role memberships independently verified live on 2026-10-22. Full LLD acceptance remains partial.'};$record | Export-Csv "$review/deployment-record.csv" -NoTypeInformation}
'Status report, 54 deployed-component rows, 17 test-status rows and requirement matrix written.'
