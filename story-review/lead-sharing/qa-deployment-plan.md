# QA deployment plan - prepared, not executed

Promote only after DEV validation, membership verification and persona acceptance tests pass. Use the approved artifact hashes and compare QA prerequisites independently; never copy DEV record IDs. The user has confirmed the criteria design. No deployment approval or org-operation authorization has been given. All commands below are future commands. Membership and external dependencies remain open; do not treat the ZIP as evidence of release readiness.

## Before execution

Confirm the actual QA org ID/alias (do not infer it from old DEV2 backups). After authorization, capture live Lead OWD/rules and group definitions AND memberships; metadata retrieval alone does not capture members. Compare all required Lead fields/values including inactive legacy entries, Role identities, group duplicates/members, rule names/counts and current settings. Preserve unrelated target rules. Confirm UST1/UST4/UST8 prerequisites and Dev 5 persona CRUD/tab access. GJT hierarchy remains unchanged by user direction; includeRecordsOwnedByAll remains false. The app is safexpress2_0 and already has standard-Lead locally.

## Execution sequence after explicit approval

1. Validate/deploy **only the 19 group definitions** using manifest/lead-sharing-groups.xml. This manifest does not select the object or any rules.
2. Perform the separately approved manual membership steps in membership-setup-steps.md and record all 72 Role assignments. Verify VH/Alliance memberships and the Safexperience initial state. Stop if membership verification fails.
3. Validate/deploy **access-payload** (Lead OWD + all 34 rules) during the approved window. Its Lead.object contains only the two OWD properties. Inactive legacy criteria are intentionally retained: Salesforce deployment acceptance and actual record matching must be verified; do not silently substitute values if validation fails.
4. Save actual deployment IDs/status, artifact hashes, membership evidence and test results in deployment-record.csv. Wait for recalculation and verify the deployed state.

Future command templates from the existing project root:

```powershell
$qaOrg = Read-Host 'Enter the verified QA alias'
sf project deploy start --target-org $qaOrg --manifest story-review/lead-sharing/manifest/lead-sharing-groups.xml --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $qaOrg --manifest story-review/lead-sharing/manifest/lead-sharing-groups.xml --api-version 67.0 --wait 60
# STOP: complete and verify the separate manual membership task.
sf project deploy start --target-org $qaOrg --metadata-dir story-review/lead-sharing/access-payload --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $qaOrg --metadata-dir story-review/lead-sharing/access-payload --api-version 67.0 --wait 60
```

lead-sharing-metadata.zip is the complete 54-component review package (package.xml at ZIP root). It does not include memberships. lead-sharing-access.zip is the phase-two 35-component package. The directory-based commands above use the same XML content as those ZIPs. Do not use the full story manifest against force-app: CustomObject Lead source selection could collect unrelated children. Never deploy the whole force-app directory for this task. The phase-one group manifest is safe to use with source selection because it lists only the 19 exact groups.

## Verification and rollback

Check all 34 names, exact criteria, AND/OR filters, targets and access levels; both Lead defaults Private; enabled group hierarchy flags; four direct Role members per region; Safexperience initial membership; unchanged app and unrelated metadata. Test each regional management role, all VH cases including legacy values on existing records, both Safexperience source values once membership is separately approved, Alliance Read and overlapping grants. An empty Safexperience group grants no access to users via that group. Test negative access with users without View All/Modify All bypasses. Account for inherited GJT/MUM access. No broad owner-population expansion is intended.

Use the target's own pre-release backup for rollback. Restoring ReadWriteTransfer broadens access and needs approval. Removing newly added rules may require a separate reviewed destructive rollback; restoring an old sharing file alone is not a deletion guarantee. No destructive manifest or membership-removal script is included. Preserve unrelated target changes and verify recalculation after rollback.