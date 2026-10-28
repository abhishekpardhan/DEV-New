throw 'Historical partial-review writer. Use write-approved-review.ps1 for the current confirmed 34-rule scope.'
$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
$base="$root/force-app/main/default"
$out=$PSScriptRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function Save($name,$text){[IO.File]::WriteAllText("$out/$name",($text -join "`r`n"),$utf8)}
function MdTable($headers,$rows){ '| '+($headers -join ' | ')+' |'; '| '+(($headers | ForEach-Object {'---'}) -join ' | ')+' |'; foreach($row in $rows){'| '+($row -join ' | ')+' |'} }
$rules=Get-Content "$out/planned-rules.json" -Raw | ConvertFrom-Json
$members=@(Import-Csv "$out/group-membership-review.csv")
$regions=@(Import-Csv "$out/region-value-review.csv")
$fields=@(Import-Csv "$out/field-review.csv")
$groupInventory=@(Import-Csv "$out/existing-group-inventory.csv")
$audit=@'
# Stream C dependency audit — 2026-10-21

Local inspection only. No Salesforce CLI command, retrieval, deployment, org query, DML, anonymous Apex, or Setup update was executed. DEV and QA identities have not been resolved. Older DEV2 artifacts/backups are not evidence of current DEV or QA state.

## Repository and evidence boundaries

`sfdx-project.json`: single default package `force-app`, namespace empty, source API **67.0**. No new project was created. This working directory is not a Git worktree; a SHA-256 baseline of all 20,630 pre-existing package files was recorded instead. Baseline copies preserve both edited XML files. No AGENTS.md file was found in the workspace search; the instructions supplied in chat were followed.

The confirmed app is `safexpress2_0` (user confirmed during this task). Its navigation is already `standard-home`, `standard-WorkbenchHome`, `standard-Campaign`, `standard-Lead`, `standard-Opportunity`. C-02 requires no edit. `Safexpress` is a separate legacy app and was not changed.

## Dependency verification

| Dependency | Status | Source evidence | Blocking issue |
| --- | --- | --- | --- |
| Package / API | VERIFIED | sfdx-project.json | force-app / 67.0 |
| Standard Lead fields | VERIFIED existence; BLOCKED some values | objects/Lead/fields and referenced value sets below | Exact value mismatches/inactive values; no replacement inferred |
| 18 regional roles, 4 per region | VERIFIED identities locally | 72 exact role paths in group-membership-review.csv | Live role identity, assignments and hierarchy still require verification |
| Role hierarchy | REQUIRES LIVE ORG VERIFICATION | role-hierarchy-review.csv | GJT New Sales and Retail report to Regional_Manager_MUM locally; Architect must resolve or accept cross-region hierarchy effects |
| Regional public groups | MISSING IN RETRIEVED METADATA before this work; BLOCKED completion | existing-group-inventory.csv | 18 definitions prepared; memberships cannot be migrated using Group metadata |
| Safexperience group | MISSING IN RETRIEVED METADATA before this work | existing-group-inventory.csv | New definition has no assignments; live existence/membership must be checked before deployment |
| Existing 14 VH groups | VERIFIED definitions; REQUIRES LIVE ORG VERIFICATION | groups/VH_*.group-meta.xml; inventory CSV | Membership is not serialized by Group metadata; absence of member XML does not mean empty |
| Alliance group | VERIFIED definition; REQUIRES LIVE ORG VERIFICATION | groups/Alliance_Partner_Management.group-meta.xml | Membership unknown; definition unchanged |
| Legacy 14 VH rules | VERIFIED exact source criteria | sharingRules/Lead__c.sharingRules-meta.xml | 12 use inactive Vertical values; Safe Returns also uses an inactive Sub-Vertical value |
| Lead OWD | VERIFIED retrieved baseline; locally changed | objects/Lead/Lead.object-meta.xml; baseline copy | Internal and external ReadWriteTransfer -> Private; deploy only after complete access model approved |
| Global SharingSettings | VERIFIED unchanged | settings/Sharing.settings-meta.xml | enableExternalSharingModel=true; global switches do not need editing |
| Standard Lead existing rules | VERIFIED retrieved baseline | baseline/Lead.sharingRules-meta.xml | Zero rules locally; live rules/count/visibility still unverified |
| Lightning app | VERIFIED locally | applications/safexpress2_0.app-meta.xml | User confirmed API name; standard-Lead already present |
| UST1 | EXTERNAL TEAM DEPENDENCY | Story request only; no acceptance/sign-off evidence supplied | Owner must confirm actual scope, standard Lead schema/value completion and delivery status |
| UST4 | EXTERNAL TEAM DEPENDENCY | Story request only; no acceptance/sign-off evidence supplied | Owner must confirm contract with Stream C and completion; no task mapping invented |
| UST8 | EXTERNAL TEAM DEPENDENCY | Story request only; no acceptance/sign-off evidence supplied | Owner must confirm contract with Stream C and completion; no task mapping invented |
| Dev 5 | EXTERNAL TEAM DEPENDENCY | User states ownership of persona tab visibility and Lead access | Confirm CRUD/tab permissions and effective-access test personas; no permission metadata changed |
| BA decisions | BLOCKED | Exact requested values compared below | Region replacements, inactive VH semantics, Web source, owner population and temporary coverage remain unapproved |
| DEV / QA parity | REQUIRES LIVE ORG VERIFICATION | No live checks authorized or performed | Confirm exact org identities, target values, groups, membership, hierarchy, rule collisions and limits |

All source paths in the table above are relative to `force-app/main/default`, except the explicit project/review files. Detailed CSVs use absolute evidence paths.

## Field definitions
'@
$rows=@(); foreach($f in $fields){$rows+= ,@($f.Field,$f.ExistsLocally,$f.Type,$f.ValueSet,$f.Source)}
$audit += "`r`n"+((MdTable @('Field','Local','Type','Value set','Exact source') $rows) -join "`r`n")
$audit += @'


Region__c, Vertical__c and Sub_Vertical__c are required, restricted picklists referencing global value sets. Sub_Vertical__c is controlled by Vertical__c. LeadSource is a standard Picklist using LeadSource.standardValueSet-meta.xml. Values with explicit isActive=false are treated as blocked for this new creation model, even though old records can retain them and a rule might still match old data. BA must decide whether legacy-only sharing is intended. No inactive values were renamed, reactivated, or substituted.

## All 18 Region values
'@
$rows=@();foreach($r in $regions){$rows+= ,@($r.Region,$r.RequiredValue,$r.Status,$r.Source)}
$audit += "`r`n"+((MdTable @('Region','Required exact value','Status','Evidence') $rows) -join "`r`n")
$audit += @'


Differences: BJO requests `BIHAR - JHARKHAND - ORISSA`, while the active retrieved value is `BIHAR - JHARKHAND - ODISHA`. KRL requests `KERALA`, while the active retrieved value is `KERALAM`. JKH's exact requested value is explicitly inactive; `JK - HP - LADAKH` is active. These are evidence of differences, not approved replacements.

`ALLIANCE PARTNER MANAGEMENT` is verified in Vertical_Global. `Safexperience Centre` is verified in standard LeadSource. `Web` is absent from that retrieved StandardValueSet; `Website` exists but was not substituted. Safexperience's one planned rule uses two equals conditions and `booleanFilter=1 OR 2`; its XML is withheld until Web is resolved.

## Public groups, memberships and hierarchy

All 20 pre-existing public groups were inspected and are listed in existing-group-inventory.csv. No duplicate API names or labels were found. All have doesIncludeBosses=true. All 14 VH groups and Alliance_Partner_Management exist locally and remain byte-for-byte unchanged. No proposed regional or Safexperience group existed in the package before this work. This is not proof of absence in DEV.

Salesforce Group metadata carries a group definition, not GroupMember assignments. Therefore new regional XML contains only doesIncludeBosses=true and a label equal to the requested API name. These are **partial definitions**, not completed groups with four roles. No invented `<groupMembers>` or `<role>` element was added to Group XML. The membership CSV records all 72 exact intended Role memberships separately. Role and Subordinates must not be used when an administrator later performs an explicitly approved assignment. Safexperience's definition proposes no initial assignments; it cannot prove or clear existing live memberships.

Group hierarchy access is enabled as requested. Role identities were resolved by exact retrieved role labels, not generated naming patterns. APT and BJO use numeric-suffixed DeveloperNames. Parent relationships are listed individually in role-hierarchy-review.csv. GJT's New Sales and Retail roles report to Regional_Manager_MUM, so users in that hierarchy may gain access. No hierarchy was repaired, and no temporary coverage was invented.

## Exact legacy mapping and all 34 planned rules

See sharing-rule-review.csv for one row per condition, with condition number, full Boolean expression, source rule name, exact field/operator/value, target group and access. See review-tables.md for the full rule table. New VH names use `SR_Lead_` followed by the existing `VH_*` group name (the VH prefix appears once). This maps the requested VH naming pattern without renaming any existing group.

Every legacy VH condition uses equals; the source has no booleanFilter, so multiple conditions use implicit AND. All source VH rules have Edit access and includeRecordsOwnedByAll=false, preserved in the two prepared rules. The six Retail VH rules require Vertical__c=`Retail Special Services` AND the exact Sub_Vertical__c value. This inactive Vertical has no matching active controlling-value mapping in standard Lead; its mappings use RETAILSPLSRV. Safe Returns is also explicitly inactive. No Type__c-based rule was selected or migrated.

Only AUTOMOTIVE and HI TECH have fully verified active exact VH criteria. The other 12 VH rules are withheld. Fifteen regional values are active and exact; three are withheld. Alliance is prepared with Read. Safexperience is withheld. Thus 18 of 34 rule XML definitions are prepared, and 16 are blocked.

For new regional and Alliance rules, includeRecordsOwnedByAll=false is a conservative proposed owner scope, consistent with the retrieved legacy rules. BA/Architect must approve it before deployment, especially for integration or automated-process-owned Leads. This field is not an ordinary editable scope switch after rule creation. It is recorded explicitly instead of silently including additional owner populations.

## OWD isolation and sharing limits

Both Lead sharing models were ReadWriteTransfer in the baseline. Exactly those two values now read Private. Standard Lead hierarchy behavior is left in place; no custom-object hierarchy toggle was added. Global Sharing.settings-meta.xml, all other object defaults, and every other existing metadata file are unchanged.

Zero existing standard Lead owner/criteria/guest rules were retrieved. There are no local rule API collisions. The full planned 34 rules are below the documented default 50 criteria-based and 300 total sharing-rule limits; confirm actual usage/limits in both orgs before release. Legacy Lead__c rules do not consume standard Lead's limit. No existing standard Lead rule was deleted or replaced. Any additional live rules must be reviewed because sharing grants are additive; they can invalidate negative visibility tests. Role hierarchy, manual shares, queues, View All/Modify All, and existing memberships likewise require effective-access tests; repository rules alone cannot prove isolation.

The manifest includes only 19 Group definitions, CustomObject Lead and 18 individual SharingCriteriaRule members. Do not deploy this manifest against the full source package: CustomObject selection/conversion can pull in Lead children and unrelated object settings. The deployment-payload directory is an isolated Metadata API representation: its Lead.object contains only the two OWD values, group files contain only reviewed definitions, and its sharing-rule container contains only the 18 prepared rules. There are no fields, layouts, flows, Apex, profiles, permission sets, global settings or destructive manifests in that payload. It is a **partial review payload**, not a release candidate. Resolve the blockers and regenerate/review it before deployment.

## Official definitions consulted

- Salesforce Metadata API Developer Guide, Group, CustomObject and SharingRules: https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/api_meta.pdf
- Group reference: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_group.htm
- SharingRules reference: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_sharingrules.htm
- CustomObject reference: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/customobject.htm
- Sharing limits: https://help.salesforce.com/s/articleView?id=000384485&language=en_US&type=1

The supplied product llms.txt endpoint and HTML reference bodies were inaccessible/empty through the browser tool. Official indexed PDF excerpts verified Group membership limitations and sharing-rule scope/filter elements. Generated elements predate API 67.0 and follow the retrieved XML representation. Local structure checks are not full Salesforce API schema/deployment validation. No deployment validation was run.
'@
Save 'dependency-audit.md' $audit
$tables=@('# Stream C review tables','','All facts below are from the local package unless explicitly stated. Group definitions are partial; memberships are not deployed.','','## Regional memberships','')
$rows=@();foreach($code in ($members.RegionCode | Select-Object -Unique)){$m=@($members | Where-Object RegionCode -ceq $code);$status='4 identities verified; membership BLOCKED';if($code -eq 'GJT'){$status+='; hierarchy review'};$rows+= ,@($m[0].PublicGroupAPIName,$m[0].RoleDeveloperName,$m[1].RoleDeveloperName,$m[2].RoleDeveloperName,$m[3].RoleDeveloperName,$status)}
$tables+=MdTable @('Group','Regional Manager','Regional ICM Manager','Regional New Sales Manager','Regional Retail Manager','Status') $rows
$tables+=@('','## All planned rules','','Edit = Read/Write; Read = Read Only. PREPARED is not deployment-ready: membership/live verification and owner-scope approval remain outstanding.','')
$rows=@();foreach($r in $rules){$criteria=@($r.Conditions | ForEach-Object {"$($_.field) $($_.operation) $($_.value)"}) -join '; ';$rows+= ,@($r.Name,$r.SourceRule,$criteria,"filter: $($r.Logic)",$r.Group,$r.Access,$(if($r.Status -eq 'VERIFIED'){'PREPARED'}else{$r.Status}))}
$tables+=MdTable @('Target rule','Legacy source rule','Exact criteria','Logic','Group','Access','Status') $rows
$tables+=@('','## Metadata completion','','| Component | Expected | Existing before task | Created | Modified | Blocked / incomplete |','| --- | --- | --- | --- | --- | --- |','| Regional groups | 18 with 72 Role memberships | 0 | 18 definitions only | 0 | 18 membership configurations |','| Safexperience group | 1 empty group | 0 | 1 definition | 0 | Live existence/empty state verification |','| Lead OWD | 1 object, two Private defaults | 1 object, both ReadWriteTransfer | 0 | 1 | Release approval and full access model |','| Regional rules | 18 | 0 | 15 rules in existing container | 1 shared container | 3 criteria; all memberships unverified |','| VH rules | 14 | 14 legacy; 0 standard Lead | 2 rules in same container | Same container | 12 inactive criteria |','| Alliance rule | 1 | 0 standard Lead | 1 rule in same container | Same container | Live group membership / owner scope approval |','| Safexperience rule | 1 | 0 | 0 | 0 | 1 missing Web value |','| App navigation | 1 | Lead tab already present | 0 | 0 | None locally; persona access is Dev 5 |','','Totals: 38 metadata components prepared (19 groups + 18 rules + 1 object OWD), across 21 source files (19 new + 2 modified). The group components do not contain assignments. 16 rules withheld. No app change. No existing VH/Alliance group edits.')
Save 'review-tables.md' $tables
$plan=@'
# DEV deployment plan — commands documented only, not executed

**STOP: current artifacts are partial and not approved for deployment.** Do not roll out Private OWD with this incomplete sharing model. No deployment, check-only request, retrieval, query or assignment is authorized by this plan alone.

## Prerequisites and dependency order

1. Obtain reviewer approval of dependency-audit.md, all 72 Role rows, all 34 rule definitions, owner-population scope and exact XML. Resolve 16 blocked rules with BA and schema owners; do not silently use ODISHA, KERALAM, JK - HP - LADAKH, new Vertical API values, or Website. Confirm UST1/UST4/UST8 delivery and Dev 5 permission work independently.
2. Confirm the actual DEV org ID and intended authenticated alias. Do not infer DEV from older DEV2 backups or the project's default alias. Confirm API 67.0 availability. After explicit authorization, take a dated baseline of live Lead OWD, rules, group definitions AND membership data, role hierarchy, app navigation, and relevant effective access. Retrieval alone does not back up group assignments.
3. Verify all field values, active/dependent mappings, target role DeveloperNames/IDs and parent roles in DEV. Resolve GJT New Sales/Retail -> MUM with the Architect. Check all 19 proposed group names for existing live definitions/members; preserve members and flag deviations, never replace them blindly. Verify the existing VH/Alliance membership and hierarchy flags. Confirm actual sharing counts/collisions; reconcile any live Lead rules without deleting unrelated ones.
4. Regenerate and review the full 34-rule payload after decisions. Confirm the app is safexpress2_0 and already contains standard-Lead. Dev 5 verifies persona CRUD, tab visibility and any View All/Modify All bypasses.
5. Create only the approved group definitions first. Prepare a separate group-only manifest from the 19 Group members in the story manifest. After that separately approved deployment, an authorized administrator assigns exactly four **Roles** per regional group, never Roles and Subordinates. This is a Setup/data operation outside this metadata-only work. Preserve Safexperience's approved empty initial membership and do not erase unexpected existing members. Export/verify assignments before proceeding.
6. In a coordinated change window, validate and deploy the final isolated OWD/rules payload after membership and other prerequisites pass. Wait for sharing recalculation. Keep OWD and complete rule activation coordinated so users do not lose necessary access between releases.

## Future command templates

Run from the existing project root only after explicit approval. Supply the confirmed org alias; it is deliberately not guessed here. Commands below are templates, not executions performed by this task.

```powershell
$devOrg = Read-Host 'Enter the verified DEV alias'
# After creating/reviewing a group-only manifest, validate it first:
sf project deploy start --target-org $devOrg --manifest story-review/lead-sharing/manifest/groups-approved.xml --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $devOrg --manifest story-review/lead-sharing/manifest/groups-approved.xml --api-version 67.0 --wait 60
# STOP until the separately approved membership operation is completed and verified.
# The payload must first be regenerated with all resolved and reviewed rules.
sf project deploy start --target-org $devOrg --metadata-dir story-review/lead-sharing/deployment-payload --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $devOrg --metadata-dir story-review/lead-sharing/deployment-payload --api-version 67.0 --wait 60
```

`groups-approved.xml` is intentionally not supplied as an approved artifact: generate it only once live duplicates, hierarchy and all membership decisions are resolved. The delivered lead-sharing-story.xml is a **partial review manifest**. Do not run `--manifest` against it in the main source tree: selecting CustomObject Lead can include unrelated children. Use only the reviewed isolated Metadata API payload for the OWD phase. Do not add --single-package or use --source-dir force-app.

## Verification after an approved deployment

Check deployment results and sharing recalculation completion, internal/external Lead OWD Private, standard hierarchy behavior, all 34 rule definitions/access levels and preserved unrelated live rules. Confirm four exact Role memberships per region, no subordinate-role memberships or unrelated users, hierarchy access enabled, and approved Safexperience membership state. Test each region's four personas, each VH vertical and all Retail AND conditions, Alliance read-only, and both Safexperience source values. Test negative cross-region/vertical visibility with users who do not have bypass permissions. Include overlapping rules, hierarchy ancestors, queue/integration ownership, null fields and Dev 5 object/tab access. Sharing grants are additive: Alliance Read does not remove Edit gained elsewhere. Record expected versus actual outcomes and obtain BA acceptance.

## Rollback

Capture target state immediately before release. Restoring prior OWD may broaden access and requires explicit approval. Restoring an older SharingRules file does not necessarily remove newly created rules; removals need a separately reviewed destructive rollback manifest, which this task does not create. Group memberships require a separate audited restoration; do not delete existing/shared groups. Restore only the approved story deltas, preserve unrelated changes and wait for recalculation. Never use the local baseline as proof of the target's pre-release state.
'@
Save 'dev-deployment-plan.md' $plan
$qa=@'
# QA promotion plan — not executed

No QA deployment is authorized. Promote only after DEV has the complete approved model, all tests pass, BA/Architect sign off and the 16 currently blocked rule requirements are resolved. The current partial payload is not a QA release candidate.

1. Confirm the exact QA org ID/alias and API 67.0 support. Obtain authorization before live queries/retrievals. Back up current QA OWD, all Lead rules, group definitions AND memberships, role IDs/DeveloperNames/parents, app and persona access. Compare against the approved DEV release, not against an old DEV2 export.
2. UST1/UST4/UST8 owners confirm their actual dependencies and acceptance; Dev 5 confirms QA Lead CRUD/tab visibility. Compare exact standard Lead fields, global/standard values, active flags, controlling mappings and owner populations. Resolve GJT hierarchy, group name collisions, group membership differences, existing unrelated rules and QA rule limits. Record QA-specific role/user IDs; never copy DEV IDs.
3. Deploy the approved group definitions first using the same reviewed group-only manifest. Separately authorized admins assign and verify exactly four Role members per regional group. Reuse existing VH/Alliance groups without modifying their members as part of Stream C. Check Safexperience's approved initial state. Stop for any unapproved existing-member deviation.
4. Promote the final approved isolated metadata payload atomically for OWD/rules; exclude fields, Apex, flows, profiles, permission sets, other objects and global settings. App navigation requires no change if standard-Lead is already present. If QA differs, obtain review of a targeted app-only delta first.

Future templates (only after explicit approval and complete regeneration):

```powershell
$qaOrg = Read-Host 'Enter the verified QA alias'
sf project deploy start --target-org $qaOrg --manifest story-review/lead-sharing/manifest/groups-approved.xml --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $qaOrg --manifest story-review/lead-sharing/manifest/groups-approved.xml --api-version 67.0 --wait 60
# Stop until separately approved membership configuration has been verified.
sf project deploy start --target-org $qaOrg --metadata-dir story-review/lead-sharing/deployment-payload --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $qaOrg --metadata-dir story-review/lead-sharing/deployment-payload --api-version 67.0 --wait 60
```

5. Verify deployment status, completed sharing recalculation, Private internal/external OWD, all 34 criteria/rule names, exact target groups/access, and unchanged unrelated rules/settings. Repeat DEV's positive and negative persona matrix for all regions/VHs/Alliance/Safexperience. Check hierarchy ancestors, overlapping additive grants, ownership/integration scenarios and Dev 5 permissions. Record QA evidence and BA acceptance; do not infer runtime behavior from XML validation.
6. Rollback must restore QA's own approved pre-release state. Reverting OWD can broaden access. Removing newly created rules requires separately approved destructive instructions; no destructive artifact is included here. Restore group membership data separately, preserve pre-existing groups and unrelated release changes, and wait for recalculation. Do not automatically apply DEV's baseline to QA.
'@
Save 'qa-deployment-plan.md' $qa
$summary=@'
# Local implementation summary

**Partial implementation; not deployment-ready; not deployed.**

Prepared 38 metadata components: 19 Group definitions, 18 standard Lead criteria rules and one Lead OWD component. This changes 21 source files: 19 created and two modified. Group definitions do not implement the 72 assignments; all regional memberships remain blocked by the Metadata API limitation and require a separately authorized operation. Safexperience has no proposed members, but live emptiness is unverified.

Created: groups/SG_RGN_<each of 18 codes>_RM.group-meta.xml and groups/Safexperience_Team.group-meta.xml. Regional labels equal their supplied API names; Safexperience label is exactly Safexperience Team. Hierarchy access is true.

Modified: objects/Lead/Lead.object-meta.xml (only sharingModel/externalSharingModel to Private); sharingRules/Lead.sharingRules-meta.xml (empty baseline now has 15 regional, 2 VH and 1 Alliance rules). No existing rules were removed.

Reused unchanged: all 14 VH group definitions, Alliance_Partner_Management, standard Lead fields and value sets, all role definitions, legacy Lead__c sharing rules, Sharing.settings-meta.xml and safexpress2_0 app. The user confirmed safexpress2_0; it already contains standard-Lead.

Skipped: BJO/JKH/KRL sharing XML; 12 inactive-criteria VH rules; Safexperience rule lacking Web; app edits; global sharing-setting edits; membership writes. No Type__c rule was migrated. No Apex, LWC, Flow, validation rule, field, profile or permission-set file was changed. No new project or destructive manifest was created.

Outstanding approvals: BA exact-value reconciliation (3 regions, 12 VH rules, Web); BA/Architect includeRecordsOwnedByAll=false owner scope for new rules; Architect GJT hierarchy; live membership/duplicate checks; the separately authorized 72 Role assignments; UST1/UST4/UST8 scope and delivery confirmations; Dev 5 persona access; full XML/manifest review and explicit later deployment approval. No temporary regional coverage is assumed.

Manifest: manifest/lead-sharing-story.xml lists only prepared story components, not blocked rules or unchanged app/dependencies. It is partial and awaits human approval. deployment-payload is an isolated equivalent Metadata API package; Lead.object contains only the two OWD settings so no unrelated object attributes/children are selected. Source manifest deployment against the full package is prohibited by the documented plan pending careful isolation review.

Review artifacts: dependency-audit.md; group-membership-review.csv (72 rows); sharing-rule-review.csv (all 34 rules, 41 condition rows); review-tables.md; region-value-review.csv; field-review.csv; existing-group-inventory.csv; role-hierarchy-review.csv; planned-rules.json; planned-memberships.json; dev-deployment-plan.md; qa-deployment-plan.md; validation-report.md; file-change-review.csv/md; baseline source hashes and original edited files. prepare-local.ps1 and write-review.ps1 record how the local artifacts were produced. prepare-local.ps1 is deliberately not rerunnable over existing story group files and must not be used as a deployment script.

Validation status is detailed in validation-report.md. Local XML parsing and structural checks are not Salesforce deployment validation. Live dependencies, membership state, target org identities, runtime sharing and effective persona access remain unverified.
'@
Save 'implementation-summary.md' $summary
Write-Output 'Dependency report, review tables, summary and both deployment plans written.'
