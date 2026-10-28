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