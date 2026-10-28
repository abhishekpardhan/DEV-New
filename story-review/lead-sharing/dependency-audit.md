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
| Field | Local | Type | Value set | Criteria support | Evidence |
| --- | --- | --- | --- | --- | --- |
| Lead.Region__c | True | Picklist | Region | VERIFIED locally: approved active values | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/objects/Lead/fields/Region__c.field-meta.xml |
| Lead.Vertical__c | True | Picklist | Vertical_Global | VERIFIED locally; inactive legacy criteria explicitly approved, picklists unchanged | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/objects/Lead/fields/Vertical__c.field-meta.xml |
| Lead.Sub_Vertical__c | True | Picklist | Sub_Vertical | VERIFIED locally; inactive legacy criteria explicitly approved, picklists unchanged | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/objects/Lead/fields/Sub_Vertical__c.field-meta.xml |
| Lead.LeadSource | True | Picklist | LeadSource (StandardValueSet) | VERIFIED locally: approved active values | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/objects/Lead/fields/LeadSource.field-meta.xml |

The custom fields are required restricted Picklists. Sub_Vertical__c is controlled by Vertical__c. Its active Retail mapping uses RETAILSPLSRV; the approved rules deliberately retain Retail Special Services and do not change dependent picklists.

## Region value audit
| Code | Approved exact criterion | Status | Evidence |
| --- | --- | --- | --- |
| APT | ANDHRA PRADESH - TELANGANA | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| BJO | BIHAR - JHARKHAND - ODISHA | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| DLI | DELHI | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| GJT | GUJARAT | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| HRN | HARYANA | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| JKH | JK - HP - LADAKH | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| KRL | KERALAM | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| KTK | KARNATAKA | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| MHG | MAHARASHTRA - GOA | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| MPC | MADHYA PRADESH - CHHATTISGARH | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| MUM | MUMBAI | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| NRE | NORTH EAST | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| PBC | PUNJAB - CHANDIGARH | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| RJN | RAJASTHAN | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| TNP | TAMILNADU - PUDUCHERRY | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| UKH | UTTARAKHAND | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| UPR | UTTAR PRADESH | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |
| WBS | WEST BENGAL - SIKKIM | VERIFIED: approved exact active value | C:\Users\80629\Downloads\SF2\DEV@New\force-app\main\default/globalValueSets/Region.globalValueSet-meta.xml |

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