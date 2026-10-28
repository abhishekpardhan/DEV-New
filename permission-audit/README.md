# Permission set regression review

Scope: local metadata in DEV@New, API 67.0. No deployment, live-org validation, or user-session testing was performed.

## Result

- 25 permission sets compared with the object-access tables supplied in this conversation: **452 object entries match**, including every Create, Read, Edit, Delete, View All and Modify All flag. Approved dependency-only Read grants are included in the baseline.
- 30 permission sets inspected in total: the 28 `PS_*` sets plus the two original `Contract_Management_Team_Read_*` sets used by the contract groups.
- 462 total object entries and 11,752 field entries inspected.
- **393 tab settings are Visible.** Changed 362 existing settings and added 12 settings for already-existing tabs. No CustomTab components were created. The original no-tab counts included empty XML properties; the final 393 count is the actual number of tab entries.
- All 17 requested group mappings match, including their 50 memberships. Every referenced permission set now exists locally.
- The post-change audit found **0 errors** in the configured checks. It reports 288 warning rows and 5 coverage notes, explained below. This is not a claim that all effective user access is verified.

## Corrections

- `PS_Invoice_Billing_Management`: set 64 field entries to Read-only, matching the read-only object access in the supplied table: Billing Information (11), Billing Line Item (18), Debit/Credit Note (17), and Payment (18).
- `PS_Opportunity_Management`: set `Opportunity.ExpectedRevenue` to Read-only.
- Updated/added existing-object tab settings to `<visibility>Visible</visibility>` across the scoped sets, including dependency-only objects and the original contract permission sets.
- Object permissions were already consistent with the supplied matrices; no object Edit permission was enabled or disabled.
- Labels, licenses, record type settings, group memberships and muting references were preserved.

## Outstanding access questions

1. **Journey Auditor:** `PS_Journey_Auditor` grants Read and View All on Journey, but not object Edit. It has 29 editable Journey fields. Field Edit alone does not allow editing existing records. No Journey Auditor access matrix was supplied here, so the object rights and field grants were preserved pending confirmation.
2. **New contract aliases:** `PS_Contract_ReadOnly` has 134 field Edit entries on objects without object Edit; `PS_Contract_ReadWrite` has 107 such entries. These are not the original permission sets used by the contract groups. The groups still use `Contract_Management_Team_Read_Only` and `Contract_Management_Team_Read_Write`, exactly as requested. No alias switch or access expansion was made. These two aliases, Journey Auditor, and the two original contract sets do not have full user-supplied access matrices in this conversation.
3. **Area Manager muting:** `PSG_AreaManager` references `PSG_AreaManager_Muted`; its metadata is still absent locally. Its restrictions and resulting effective access cannot be checked. The reference was preserved and this component must exist in the target org.
4. **Parent sharing:** 17 set/object combinations have a writable detail object whose master-detail relationship requires write sharing to its parent, while that set does not grant parent object Edit. See `results.csv` entries with `Check=ParentWriteSharing`. These are not automatically broadened beyond the approved tables. For example, Target permits Quote Line Item editing but grants Quote Read-only; many sets permit Contact Billing Line Item editing but grant Billing Line Item Read-only. Validate actual user access with all profiles, sets, groups and record sharing in the org.

The inactive `Case__c.Customer_Portal_Access` record type is not required by the active-record-type coverage check and was not re-added or activated. All locally active record types for table-backed business objects with field access are checked. Dependency-only grants do not acquire extra field or record-type permissions.

Create/Read-only object rows remain Create/Read-only, as requested. These include Idea and selected Billing, Campaign and Integration Transaction entries. Their field editability follows the previously agreed rule based on object Edit, so record-creation forms for these rows also need a live-user check. Platform event FLS is not applicable.

## Artifacts

- `object-access.csv`: every audited object's six permission flags and expected matrix.
- `results.csv`: post-change warnings and coverage notes.
- `summary-results.csv`: counts per set.
- `changes.csv`: issues found in the repair pass; these are historical findings, not the final unresolved-error count.
- `field-changes.csv`: exact before/after field changes.
- `before/`: pre-change copies of the modified permission sets.
- `../scripts/permission-set-regression.ps1`: repeatable local regression audit. Run with `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/permission-set-regression.ps1` from the workspace. `-Fix` applies table-backed corrections and Visible tab settings. Unknown object-access policies remain unchanged.
- `../manifest/permission-set-regression-deploy.xml`: focused deployment package for all 30 audited sets and 17 groups. The existing wildcard `manifest/package.xml` was not changed.

Before deploying, review the five sets without a supplied matrix. The focused manifest includes their current rights; it does not imply those rights were approved by an access table. Muting metadata is not included because it is absent locally.

## Verification limits and official references

Local checks cover XML parsing, exact supplied object matrices, field metadata and editability, required/master-detail field exclusions, parent Read dependencies, tab references and visibility, active record-type coverage, duplicate fields/objects, group memberships, and manifest component existence.

They do not verify deployed metadata, license availability, permission-set assignments, muting effects, page layouts, record ownership/sharing, restriction rules, validation rules, or runtime UI/API success. No Apex behavior was changed or Apex tests run.

- [Salesforce Metadata API guide — PermissionSet and tab settings](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/api_meta.pdf)
- [Salesforce permission and access settings](https://help.salesforce.com/s/articleView?id=permissions_about_users_access.htm&language=en_US)
- [Master-detail writeRequiresMasterRead semantics](https://developer.salesforce.com/docs/platform/api/guide/sforce-api-calls-describesobjects-describesobjectresult.html)
- [Page-layout read-only settings can prevent editing despite permission-set access](https://help.salesforce.com/s/articleView?id=000383135&language=en_US&type=1)
