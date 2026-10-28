# Resolution of the supplied deployment failure

## What the supplied log shows

The attempt failed with eight field-level errors. The log explicitly says no metadata changes were applied; this is the supplied deployment result, not an independently queried org state.

The attempted payload resolved to force-app/main/default/objects/Lead and included fields, compact layouts, validation rules, list views and web links. It even proposed creating Support_Case__c and updating validation rules, which are outside Stream C. This is evidence of source selection expanding CustomObject Lead into its children. The exact command or UI action was not included in the log.

| Field | Reported error |
| --- | --- |
| ActionCadenceAssigneeId | Does not resolve to a valid sObject type |
| ActionCadenceId | Does not resolve to a valid sObject type |
| ActionCadenceState | Could not resolve standard field name |
| ActiveTrackerCount | Could not resolve standard field name |
| FirstCallDateTime | Could not resolve standard field name |
| FirstEmailDateTime | Could not resolve standard field name |
| IqScore | Could not resolve standard field name |
| ScheduledResumeDateTime | Could not resolve standard field name |

The target rejected these field definitions. The log alone does not establish which target feature, license or version difference caused the rejection. No field rename, deletion, enablement change or field XML modification is needed for this sharing-only package. The 34 sharing rules and 19 groups have no file-level errors in the supplied result; that does not mean they were deployed or fully validated independently.

## Correct deployment input

Use the existing isolated Metadata API directory **deployment-payload**, not a source-format deployment of the full story manifest or a right-click Deploy Source action on package.xml. A manifest is a selector; it does not restrict source conversion to the two properties inside the Lead object file. The isolated directory contains only:

- 19 Group definition files;
- objects/Lead.object with sharingModel=Private and externalSharingModel=Private only;
- sharingRules/Lead.sharingRules with all 34 rules;
- package.xml with 54 component entries.

The supplied eight failing fields, other fields, validation rules and other Lead child components are absent from this directory and from lead-sharing-metadata.zip. No deployable XML needed changing for this error.

## Validate the isolated package first

From C:\Users\80629\Downloads\SF2\DEV@New, enter the confirmed target alias or username. The following command is provided for the user; the assistant has not executed it. It performs Salesforce validation without committing the package.

```powershell
$org = Read-Host 'Enter the verified target org alias or username'
sf project deploy start --target-org $org --metadata-dir story-review/lead-sharing/deployment-payload --api-version 67.0 --dry-run --wait 60
```

Do not add --manifest or --source-dir to this command. Do not use --ignore-errors. Review any new validation output; excluding these unrelated fields addresses the eight reported field errors but does not guarantee that no other org dependency exists.

## Actual rollout sequence, after review and approval

1. Validate and deploy the group-only source manifest. This manifest lists only Group components and cannot select Lead children:

```powershell
sf project deploy start --target-org $org --manifest story-review/lead-sharing/manifest/lead-sharing-groups.xml --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $org --manifest story-review/lead-sharing/manifest/lead-sharing-groups.xml --api-version 67.0 --wait 60
```

2. Follow membership-setup-steps.md to assign and verify the four direct Roles per regional group. Use membership-setup-checklist.csv, preserve unexpected existing members pending review, and leave Safexperience initially empty as agreed. Confirm existing VH/Alliance memberships and other target prerequisites.
3. Validate and deploy the access-only Metadata API directory:

```powershell
sf project deploy start --target-org $org --metadata-dir story-review/lead-sharing/access-payload --api-version 67.0 --dry-run --wait 60
sf project deploy start --target-org $org --metadata-dir story-review/lead-sharing/access-payload --api-version 67.0 --wait 60
```

4. Record actual deployment IDs/results, wait for recalculation and run the documented access tests. The current package retains the approved inactive VH criteria; runtime matching remains a separate verification.

Official CLI reference: https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_project_deploy_start.html

Local investigation only: no new org query, retrieval, validation, deployment, Setup update or DML was executed while diagnosing this failure.
