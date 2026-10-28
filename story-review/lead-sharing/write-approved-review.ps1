$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
$base="$root/force-app/main/default"
$out=$PSScriptRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function Save($name,$text){[IO.File]::WriteAllText("$out/$name",($text -join "`r`n"),$utf8)}
function Table($head,$rows){'| '+($head -join ' | ')+' |';'| '+(($head | ForEach-Object {'---'}) -join ' | ')+' |';foreach($row in $rows){'| '+($row -join ' | ')+' |'}}
$rules=Get-Content "$out/planned-rules.json" -Raw | ConvertFrom-Json
$members=Import-Csv "$out/group-membership-review.csv"
$regions=Import-Csv "$out/region-value-review.csv"
$fields=Import-Csv "$out/field-review.csv"
$decisions=@'
# Approved configuration decisions - 2026-10-21

The user's latest confirmation supersedes the original criteria for the following rules. It authorizes local preparation only, not deployment or membership writes.

| Item | Previous request/proposal | Confirmed local XML |
| --- | --- | --- |
| BJO | BIHAR - JHARKHAND - ORISSA | BIHAR - JHARKHAND - ODISHA |
| KRL | KERALA | KERALAM |
| JKH | JAMMU KASHMIR - HIMACHAL PRADESH | JK - HP - LADAKH |
| Safexperience | Web OR Safexperience Centre | Website OR Safexperience Centre |
| 12 VH rules | Withheld because legacy values are inactive | Retain exact legacy criteria, including inactive values |
| GJT hierarchy | Review requested for New Sales/Retail -> MUM | User directed no concern/change; retain existing hierarchy |
| Owner population | Proposed includeRecordsOwnedByAll=false | Retain false; user expressed no preference; no scope expansion |
| App | safexpress2_0 | Confirmed earlier; standard-Lead already present; no edit |

All 14 VH criteria are copied exactly from Lead__c, with the same groups, Edit access and false owner-population flag. Six Retail rules use AND. The Safe Returns rule also retains its inactive Sub_Vertical__c value. Picklist definitions and active flags are unchanged. These rules match legacy values when present on standard Lead records; they do not map newer values such as APPARELS, HEALTH, BOOKS or RETAILSPLSRV to the old values. Whether DEV/QA accept and evaluate each inactive criterion remains an org validation/runtime check, not a local guarantee.

The hierarchy decision does not prove the current hierarchy is region-isolated: existing GJT -> MUM inheritance remains. The retained false flag excludes the additional owner populations controlled by includeRecordsOwnedByAll. No role, user assignment or group membership was changed.
'@
Save 'approved-decisions.md' $decisions
$audit=@'
# Stream C dependency audit - current confirmed revision

Repository inspection only. No CLI call, org query, retrieve, deployment, DML, anonymous Apex, or Setup change has been performed. The user's decisions are recorded in approved-decisions.md. All prior value-based blocks are resolved for local XML preparation; live checks, memberships and external team dependencies remain outstanding.

## Package and existing state

`sfdx-project.json` defines the existing default package `force-app`, empty namespace and API 67.0. No new project was created. The workspace is not a Git worktree, so baseline/source-hashes.csv records all 20,630 original source files. The baseline object/rule files retain the initial retrieved state. baseline/pre-confirmation-Lead.sharingRules-meta.xml preserves the intermediate 18-rule draft.

Paths below are relative to force-app/main/default unless a review path is specified. CSV evidence paths are absolute. Older DEV2 backups are not treated as current DEV or QA evidence.

| Dependency | Status | Source evidence | Remaining issue |
| --- | --- | --- | --- |
| Package/API | VERIFIED | sfdx-project.json | force-app / 67.0 |
| Standard Lead fields | VERIFIED locally | objects/Lead/fields/{Region__c,Vertical__c,Sub_Vertical__c,LeadSource}.field-meta.xml | Must match target org before deployment |
| 18 Region criteria | VERIFIED locally / user confirmed | globalValueSets/Region.globalValueSet-meta.xml | BJO ODISHA, KRL KERALAM, JKH JK - HP - LADAKH now used |
| 14 VH criteria | VERIFIED exact legacy mapping; inactive use approved | sharingRules/Lead__c.sharingRules-meta.xml and value sets | 12 retain inactive Vertical values; Safe Returns also inactive; org acceptance/runtime not verified |
| Alliance criterion | VERIFIED locally | globalValueSets/Vertical_Global.globalValueSet-meta.xml | ALLIANCE PARTNER MANAGEMENT present |
| Safexperience criterion | VERIFIED locally / user confirmed | standardValueSets/LeadSource.standardValueSet-meta.xml | Website OR Safexperience Centre; one rule with 1 OR 2 |
| 72 regional role identities | VERIFIED locally | group-membership-review.csv and exact Role paths | Actual live identities/assignments unverified |
| Role hierarchy | USER DIRECTED NO CHANGE | role-hierarchy-review.csv | GJT New Sales and Retail still report to MUM in source; live state unverified |
| 18 regional group definitions | XML PREPARED; originally MISSING IN RETRIEVED METADATA | groups/SG_RGN_*_RM.group-meta.xml | Memberships require separate approved Setup/data action |
| Safexperience group | XML PREPARED; originally MISSING IN RETRIEVED METADATA | groups/Safexperience_Team.group-meta.xml | No initial assignments; live existence/empty state unverified |
| 14 VH and Alliance groups | VERIFIED definitions, unchanged | existing-group-inventory.csv | Membership not represented by Group XML; verify in target |
| Lead OWD | XML PREPARED | objects/Lead/Lead.object-meta.xml | Both ReadWriteTransfer -> Private; membership/access preparation before rollout |
| Global SharingSettings | VERIFIED unchanged | settings/Sharing.settings-meta.xml | enableExternalSharingModel=true locally; no global edits |
| Existing Lead sharing rules | VERIFIED retrieved baseline empty | baseline/Lead.sharingRules-meta.xml | Live rules/count/collisions must be checked; preserve unrelated rules |
| safexpress2_0 app | VERIFIED locally / user confirmed | applications/safexpress2_0.app-meta.xml | standard-Lead already present; no edit |
| UST1 | EXTERNAL TEAM DEPENDENCY | Story request only | Owner confirms scope, prerequisites and acceptance; no completion evidence |
| UST4 | EXTERNAL TEAM DEPENDENCY | Story request only | Owner confirms scope, prerequisites and acceptance; no completion evidence |
| UST8 | EXTERNAL TEAM DEPENDENCY | Story request only | Owner confirms scope, prerequisites and acceptance; no completion evidence |
| Dev 5 | EXTERNAL TEAM DEPENDENCY | User-defined ownership | Persona Lead CRUD/tab visibility and bypass permissions must be verified |
| DEV/QA | REQUIRES LIVE ORG VERIFICATION | No org operations | Exact identities, metadata parity, live group memberships, limits and effective access |

## Field audit
'@
$rows=@();foreach($f in $fields){$rows+= ,@($f.Field,$f.ExistsLocally,$f.Type,$f.ValueSet,$f.Status,$f.Source)}
$audit+="`r`n"+((Table @('Field','Local','Type','Value set','Criteria support','Evidence') $rows)-join "`r`n")
$audit+="`r`n`r`nThe custom fields are required restricted Picklists. Sub_Vertical__c is controlled by Vertical__c. Its active Retail mapping uses RETAILSPLSRV; the approved rules deliberately retain Retail Special Services and do not change dependent picklists.`r`n`r`n## Region value audit`r`n"
$rows=@();foreach($r in $regions){$rows+= ,@($r.Region,$r.RequiredValue,$r.Status,$r.Source)}
$audit+=((Table @('Code','Approved exact criterion','Status','Evidence') $rows)-join "`r`n")
$audit+=@'


## Groups and exact legacy mapping

All 20 original Group definitions were inspected; no duplicate API names or labels were found, and all have doesIncludeBosses=true. The 14 VH and Alliance definitions are unchanged. The 18 proposed regional groups and Safexperience were absent locally before this work; this does not prove absence in the org. Membership cannot be inferred from the Group files. The 19 new definitions also use doesIncludeBosses=true. Regional labels equal their supplied API names; Safexperience uses the exact label Safexperience Team.

group-membership-review.csv records 72 exact Role DeveloperNames, four per region. membership-setup-checklist.csv adds the corresponding UI labels and explicit NOT PERFORMED/NOT VERIFIED cells for DEV/QA. APT/BJO numeric-suffixed names are preserved. No Role-and-Subordinates member is proposed. GJT inheritance is retained as directed.

sharing-rule-review.csv records all 34 rules as 41 condition rows with exact fields, operators, values, Boolean filters, target groups, access and legacy source rule names. All 14 legacy VH rules use equals, Edit and includeRecordsOwnedByAll=false. Missing source filters mean AND, now explicit for two-condition rules. New names are SR_Lead_ plus the existing VH_* group API name, so VH appears once. No Type__c rules are copied. Read is used only for Alliance; the other 33 use Edit. Safexperience uses two equals conditions with 1 OR 2. All 34 rules retain includeRecordsOwnedByAll=false.

## Sharing and application checks

The original standard Lead container was empty. This revision appends 16 approved rules to the earlier 18-rule draft, preserving all 18 definitions and any other pre-existing nodes. There are 18 regional, 14 VH, one Alliance and one Safexperience rules. The planned 34 criteria rules fit within the documented default 50 criteria/300 total limits; live counts and any overrides must still be checked. Existing live grants and bypass permissions can affect visibility even when absent from this retrieved snapshot. Sharing grants are additive; Alliance Read cannot revoke Edit granted by another rule or hierarchy.

Only the two Lead sharing-model values differ from the original object file. Global SharingSettings and all other object defaults are unchanged. Standard Lead hierarchy behavior remains in place. App navigation is standard-home, standard-WorkbenchHome, standard-Campaign, standard-Lead, standard-Opportunity. No app, field, picklist, role, profile, permission set, Flow, Apex, LWC or legacy sharing file was edited.

The complete manifest contains 54 components: 19 groups, Lead OWD and 34 individual SharingCriteriaRule members. Do not use this full manifest against the entire source tree: selecting CustomObject Lead can collect unrelated children. Use the isolated Metadata API payloads instead. deployment-payload has all 54 components; access-payload has only Lead OWD and the 34 rules. Their Lead.object contains only sharingModel and externalSharingModel. No destructive metadata is included.

## Official references and limits of validation

- Group definition and membership exclusion: https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/api_meta.pdf
- Setup membership steps: https://help.salesforce.com/s/articleView?id=platform.creating_and_editing_groups.htm&language=en_US&type=5
- Sharing rules limits: https://help.salesforce.com/s/articleView?id=000384485&language=en_US&type=1

Metadata elements follow the retrieved representation and established API definitions compatible with 67.0. Local XML/structure checks are not full Salesforce schema or deployment validation. Inactive criterion acceptance, sharing recalculation, effective access and target org parity remain untested. All files are local preparations, not proof of deployment.
'@
Save 'dependency-audit.md' $audit
$tables=@('# Current review tables','','All 34 rules are prepared under the confirmed design. Memberships are not assigned and live dependencies are outstanding.','','## Regional roles','')
$rows=@();foreach($code in ($members.RegionCode | Select-Object -Unique)){$m=@($members | Where-Object RegionCode -ceq $code);$rows+= ,@($m[0].PublicGroupAPIName,$m[0].RoleDeveloperName,$m[1].RoleDeveloperName,$m[2].RoleDeveloperName,$m[3].RoleDeveloperName,'Identities verified locally; assignments NOT PERFORMED')}
$tables+=Table @('Group','Regional Manager','Regional ICM Manager','Regional New Sales Manager','Regional Retail Manager','Status') $rows
$tables+=@('','## All 34 rules','','Edit = Read/Write; Read = Read Only. Approved inactive criteria remain unchanged in picklists.','')
$rows=@();foreach($r in $rules){$criteria=@($r.Conditions | ForEach-Object {"$($_.field) $($_.operation) $($_.value)"}) -join '; ';$rows+= ,@($r.Name,$r.SourceRule,$criteria,$r.Logic,$r.Group,$r.Access,$r.Status)}
$tables+=Table @('Target rule','Legacy source','Exact criteria','Boolean logic','Group','Access','Status') $rows
$tables+=@('','## Metadata completion','','| Component | Expected | Existing initially | Created | Modified | Remaining |','| --- | --- | --- | --- | --- | --- |','| Regional groups | 18 with 72 Role members | 0 locally | 18 definitions | 0 | All 72 assignments |','| Safexperience group | 1 initially empty | 0 locally | 1 definition | 0 | Live initial state verification |','| Lead OWD | 1 object / two Private settings | Both ReadWriteTransfer | 0 | 1 object | Deployment and runtime checks |','| Regional rules | 18 | 0 standard Lead | 18 | Existing container | Live checks |','| VH rules | 14 | 14 legacy / 0 Lead | 14 | Same container | Inactive criteria org acceptance/runtime |','| Alliance rule | 1 | 0 Lead | 1 | Same container | Live membership and access |','| Safexperience rule | 1 | 0 | 1 | Same container | Empty group means no member access initially |','| App | Lead tab | Already present | 0 | 0 | Dev 5 persona access |','','54 metadata components prepared; 19 new source files and two modified relative to the original baseline. This revision adds 16 rules without changing the prior 18. No deployment or membership operation performed.')
Save 'review-tables.md' $tables
$setup=@'
# Public-group membership steps

This is a manual Setup task after group definition deployment. No GroupMember operation has been run. Metadata XML cannot carry these assignments. Use an administrator with access to manage the target public groups; confirm the target org before editing.

1. Review the target's existing groups, members and exact role labels/DeveloperNames. If a proposed group already has unexpected members, preserve them and obtain review; do not delete or silently replace them.
2. After the approved group-only deployment, open **Setup -> Quick Find: Public Groups -> Public Groups**.
3. Find the exact **Group Name/API name** from membership-setup-checklist.csv, for example SG_RGN_APT_RM. Click **Edit**.
4. Keep **Grant Access Using Hierarchies** selected.
5. In the **Search** member-type dropdown choose **Roles**. Do not choose any Roles and Subordinates option. Search the RoleLabel from the checklist, select it and click **Add**.
6. Add the four regional management roles for that one group: Regional Manager, Regional ICM Manager, Regional New Sales Manager, Regional Retail Manager. The checklist gives all 72 exact DeveloperNames and UI labels. Do not substitute National Sales Manager for New Sales Manager.
7. Save, reopen and verify the four intended direct Role members, with no extra users/groups/subordinate-role memberships. Repeat for all 18 groups. If there were unexpected pre-existing members, resolve the discrepancy before claiming exactly four.
8. Safexperience_Team remains initially without assigned members. Do not remove unexpected existing live members without review. Existing VH_* and Alliance_Partner_Management groups are reused unchanged; verify their membership separately.
9. Record DEVAdded/DEVVerified in the checklist using actual results. Repeat independently in QA after promotion; do not copy DEV record IDs. Retain screenshots or a target-specific member export as evidence.
10. Only after membership verification and external dependencies are satisfied, validate/deploy the isolated access payload, then wait for sharing recalculation and test persona visibility.

Example APT roles to select in the UI:

| UI role label | Exact DeveloperName |
| --- | --- |
| Regional Manager APT | Regional_Manager_1 |
| Regional ICM Manager APT | Regional_ICM_Manager_1 |
| Regional New Sales Manager APT | Regional_New_Sales_Manager_1 |
| Regional Retail Manager APT | Regional_Retail_Manager_1 |

No automation or data import is necessary for the manual route. A separately approved GroupMember API/import workflow could be prepared later, but would require target-org IDs and duplicate checks; it is not part of this XML package.

Official reference: https://help.salesforce.com/s/articleView?id=platform.creating_and_editing_groups.htm&language=en_US&type=5
'@
Save 'membership-setup-steps.md' $setup
$dev=@'
# DEV deployment plan - prepared, not executed

The user has confirmed the criteria design. No deployment approval or org-operation authorization has been given. All commands below are future commands. Membership and external dependencies remain open; do not treat the ZIP as evidence of release readiness.

## Before execution

Confirm the actual DEV org ID/alias (do not infer it from old DEV2 backups). After authorization, capture live Lead OWD/rules and group definitions AND memberships; metadata retrieval alone does not capture members. Compare all required Lead fields/values including inactive legacy entries, Role identities, group duplicates/members, rule names/counts and current settings. Preserve unrelated target rules. Confirm UST1/UST4/UST8 prerequisites and Dev 5 persona CRUD/tab access. GJT hierarchy remains unchanged by user direction; includeRecordsOwnedByAll remains false. The app is safexpress2_0 and already has standard-Lead locally.

## Execution sequence after explicit approval

1. Validate/deploy **only the 19 group definitions** using manifest/lead-sharing-groups.xml. This manifest does not select the object or any rules.
2. Perform the separately approved manual membership steps in membership-setup-steps.md and record all 72 Role assignments. Verify VH/Alliance memberships and the Safexperience initial state. Stop if membership verification fails.
3. Validate/deploy **access-payload** (Lead OWD + all 34 rules) during the approved window. Its Lead.object contains only the two OWD properties. Inactive legacy criteria are intentionally retained: Salesforce deployment acceptance and actual record matching must be verified; do not silently substitute values if validation fails.
4. Save actual deployment IDs/status, artifact hashes, membership evidence and test results in deployment-record.csv. Wait for recalculation and verify the deployed state.

Future command templates from the existing project root:

```powershell
$devOrg = Read-Host 'Enter the verified DEV alias'
sf project deploy start --target-org $devOrg --manifest story-review/lead-sharing/manifest/lead-sharing-groups.xml --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $devOrg --manifest story-review/lead-sharing/manifest/lead-sharing-groups.xml --api-version 67.0 --wait 60
# STOP: complete and verify the separate manual membership task.
sf project deploy start --target-org $devOrg --metadata-dir story-review/lead-sharing/access-payload --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $devOrg --metadata-dir story-review/lead-sharing/access-payload --api-version 67.0 --wait 60
```

lead-sharing-metadata.zip is the complete 54-component review package (package.xml at ZIP root). It does not include memberships. lead-sharing-access.zip is the phase-two 35-component package. The directory-based commands above use the same XML content as those ZIPs. Do not use the full story manifest against force-app: CustomObject Lead source selection could collect unrelated children. Never deploy the whole force-app directory for this task. The phase-one group manifest is safe to use with source selection because it lists only the 19 exact groups.

## Verification and rollback

Check all 34 names, exact criteria, AND/OR filters, targets and access levels; both Lead defaults Private; enabled group hierarchy flags; four direct Role members per region; Safexperience initial membership; unchanged app and unrelated metadata. Test each regional management role, all VH cases including legacy values on existing records, both Safexperience source values once membership is separately approved, Alliance Read and overlapping grants. An empty Safexperience group grants no access to users via that group. Test negative access with users without View All/Modify All bypasses. Account for inherited GJT/MUM access. No broad owner-population expansion is intended.

Use the target's own pre-release backup for rollback. Restoring ReadWriteTransfer broadens access and needs approval. Removing newly added rules may require a separate reviewed destructive rollback; restoring an old sharing file alone is not a deletion guarantee. No destructive manifest or membership-removal script is included. Preserve unrelated target changes and verify recalculation after rollback.
'@
Save 'dev-deployment-plan.md' $dev
$qa=$dev.Replace('# DEV deployment plan','# QA deployment plan').Replace('actual DEV org','actual QA org').Replace('verified DEV alias','verified QA alias').Replace('$devOrg','$qaOrg')
$qa=$qa.Replace('The user has confirmed the criteria design.','Promote only after DEV validation, membership verification and persona acceptance tests pass. Use the approved artifact hashes and compare QA prerequisites independently; never copy DEV record IDs. The user has confirmed the criteria design.')
Save 'qa-deployment-plan.md' $qa
$summary=@'
# Current implementation summary

All requested metadata XML is now prepared under the user's confirmed criteria. **Not deployed; memberships and live dependencies remain outstanding.**

- 54 components: 19 Group definitions + 34 SharingCriteriaRule components + Lead OWD.
- 34 rules: 18 regional, 14 VH, one Alliance Read, one Safexperience Edit. All other rules use Edit.
- This revision appended 16 rules to the earlier draft; the previous 18 definitions were preserved.
- Updated approved criteria: BJO uses BIHAR - JHARKHAND - ODISHA; KRL uses KERALAM; JKH uses JK - HP - LADAKH; Safexperience uses Website OR Safexperience Centre with 1 OR 2.
- The 12 previously withheld VH rules retain their exact inactive legacy criteria as explicitly requested. No picklist is modified or reactivated. No Type__c rule is migrated.
- GJT hierarchy is unchanged as directed. All rules retain includeRecordsOwnedByAll=false; no additional owner populations are enabled.
- Relative to the original repository snapshot: 19 new source files, two modified source files and no deletions. Only Lead.object-meta.xml (two OWD values) and Lead.sharingRules-meta.xml differ among pre-existing source files. No additional source file is modified in this revision.
- App safexpress2_0 already includes standard-Lead and is unchanged. Existing VH/Alliance groups, roles, fields, value sets, global sharing settings, permission sets, profiles, Apex, Flows and LWC remain unchanged.
- Regional Group definitions cannot contain actual membership assignments. All 72 exact Role identities are recorded, but assignments are NOT PERFORMED. Safexperience has no proposed initial members; live state unverified.

## Deliverables to review

Start with README-review.md. deployment-payload/package.xml and lead-sharing-metadata.zip contain the complete isolated metadata package. access-payload and lead-sharing-access.zip contain the phase-two OWD/rules package. manifest/lead-sharing-groups.xml is phase one. membership-setup-steps.md and membership-setup-checklist.csv guide the manual assignment phase. source-change-review.md/csv list exact before/after metadata changes. deployment-checksums.csv fingerprints the packages; deployment-record.csv is an uncompleted actual-release evidence template. dependency-audit.md, review-tables.md, sharing-rule-review.csv and validation-report.md provide the checks.

No CLI command or Salesforce org operation was executed. Local XML checks do not prove org deployment acceptance, especially for the deliberately inactive criteria. DEV/QA identities, current membership/metadata parity, limits, role assignments, UST1/UST4/UST8 and Dev 5 dependencies still require verification.

prepare-local.ps1 and write-review.ps1 are historical scripts disabled to prevent recreating outdated partial reports. update-approved.ps1 and write-approved-review.ps1 produce the current local artifacts; validate-local.ps1 checks the current revision. All scripts are excluded from deployment packages.
'@
Save 'implementation-summary.md' $summary
$changes=@([pscustomobject]@{Component='Lead';Path="$base/objects/Lead/Lead.object-meta.xml";Property='sharingModel';Original='ReadWriteTransfer';Current='Private';ThisRevision='Unchanged from prior draft'},[pscustomobject]@{Component='Lead';Path="$base/objects/Lead/Lead.object-meta.xml";Property='externalSharingModel';Original='ReadWriteTransfer';Current='Private';ThisRevision='Unchanged from prior draft'})
[xml]$prior=Get-Content "$out/baseline/pre-confirmation-Lead.sharingRules-meta.xml"
foreach($r in $rules){$changes += [pscustomobject]@{Component="Lead.$($r.Name)";Path="$base/sharingRules/Lead.sharingRules-meta.xml";Property='Criteria-based sharing rule';Original='Absent in original retrieved Lead container';Current=(@($r.Conditions | ForEach-Object {"$($_.field) $($_.operation) $($_.value)"}) -join '; ')+"; filter=$($r.Logic); group=$($r.Group); access=$($r.Access); includeRecordsOwnedByAll=false";ThisRevision=$(if($r.Name -cin @($prior.SharingRules.sharingCriteriaRules.fullName)){'Preserved previous draft rule'}else{'Added following user confirmation'})}}
foreach($g in @($members.PublicGroupAPIName | Select-Object -Unique)+@('Safexperience_Team')){$changes += [pscustomobject]@{Component=$g;Path="$base/groups/$g.group-meta.xml";Property='Group definition';Original='Absent from original local package; live state unknown';Current='doesIncludeBosses=true; definition only, no membership assignment';ThisRevision='Unchanged from prior draft'}}
$changes | Export-Csv "$out/source-change-review.csv" -NoTypeInformation
$text=@('# Exact source change review','','Relative to the original retrieved snapshot, only two existing source files change and 19 new group definitions are added. This revision appends 16 rules; no original draft rule is changed. The table is metadata intent, not a record of a deployment.','','The complete deployable XML is in deployment-payload. Baseline copies and SHA-256 source hashes are retained under baseline.','','| Component | Full file path | Property | Original retrieved state | Current local state | This revision |','| --- | --- | --- | --- | --- | --- |')
foreach($c in $changes){$text+="| $($c.Component) | $($c.Path) | $($c.Property) | $($c.Original) | $($c.Current) | $($c.ThisRevision) |"};Save 'source-change-review.md' $text
if(!(Test-Path "$out/deployment-record.csv")){
    $record=@();foreach($org in @('DEV','QA')){foreach($step in @('Confirm target identity and live baseline','Validate group XML','Deploy group definitions','Assign and verify 72 Role memberships','Validate access XML','Deploy OWD and 34 rules','Wait for recalculation and run visibility tests')){$record += [pscustomobject]@{Environment=$org;Step=$step;Status='NOT PERFORMED';ActualOrgId='';ActualDeploymentId='';PerformedAt='';ArtifactSHA256='';EvidencePath='';Notes=''}}};$record | Export-Csv "$out/deployment-record.csv" -NoTypeInformation
}
Save 'README-review.md' @'
# Lead sharing - review and next steps

**All 34 rule XML definitions are prepared. Nothing is deployed.** Read approved-decisions.md for the user's confirmed changes.

1. Review **deployment-payload/package.xml**, **deployment-payload/sharingRules/Lead.sharingRules** and **deployment-payload/objects/Lead.object**. Group XML is in deployment-payload/groups. **lead-sharing-metadata.zip** contains that exact complete package: 19 groups, 34 rules and Lead OWD. A package manifest lists components; the separate XML files carry their definitions.
2. Review **source-change-review.md** for the before/after values and **file-change-review.md** for every full file path. **deployment-checksums.csv** identifies the exact artifacts you reviewed.
3. After target checks and explicit deployment approval, deploy the group-only manifest **manifest/lead-sharing-groups.xml**.
4. In **Setup -> Public Groups**, add the four exact **Roles** to each regional group using **membership-setup-checklist.csv**. Full steps are in **membership-setup-steps.md**. No Role-and-Subordinates memberships. Safexperience remains initially empty; preserve/report any unexpected live members.
5. After memberships are verified, validate/deploy **access-payload** (or its equivalent **lead-sharing-access.zip**) for Private/Private Lead OWD and the 34 rules. Future commands are in **dev-deployment-plan.md** and **qa-deployment-plan.md**. Do not deploy the full source directory or select CustomObject Lead from it.
6. Record actual deployment IDs, hashes and test evidence in **deployment-record.csv**. Wait for recalculation and test access. The CSV currently says NOT PERFORMED; no deployment success is claimed.

Memberships cannot be packaged in Group metadata XML. The metadata package and the separate membership setup together implement the model. Existing VH/Alliance groups, Lead fields/value sets, role hierarchy, permission metadata and the app are not deployed by this package. Required existing dependencies must therefore be present in each target org.

The approved inactive VH values are retained exactly; they do not match replacement active values automatically. Safexperience's group initially has no members, so its rule initially grants no user access through that group. Remaining live/external-team checks are in dependency-audit.md.
'@
'Current reports, source delta and separate membership instructions written.'
