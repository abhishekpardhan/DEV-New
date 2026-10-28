# Dev1 role-deletion dependency cleanup

Date: 2026-10-22

Org: Dev1 / Safexpress Private Limited / 00DC1000005VGonMAG

## Successful deployment

- Deployment ID: `0AfC1000009wN8jKAE`
- Status: Succeeded
- Check only: false
- Approval process `Case__c.Auto_approved_claim_and_ccd`:
  - Removed the 30 target role submitters from the failed deletion list.
  - Removed 388 additional stale role submitters verified as absent from live Dev1.
  - Preserved 514 role submitters verified against live Dev1 roles.
- Deleted workflow alert `Lead__c.Send_Email_To_3pl`.
- Deleted nine role-targeted sharing rules listed in `destructiveChangesPost.xml`.
- Sharing recalculation completed for Account, Lead, and Opportunity.

## Queue follow-up

The local queue XML now contains an explicit empty `<queueMembers/>` collection for `Lead_Central_Team_3PL`. The live queue still contains the `X3PL_Head` role group because the queue-only deployment was blocked by a concurrent Salesforce group-membership operation.

- Failed queue-only deployment ID: `0AfC1000009wMxSKAU`
- Error: `a group membership operation initiated by user ID 005C1000008h1eA is already in progress`
- No direct GroupMember DML was performed.

## Concurrent role deletion

Setup Audit Trail showed that 17 of the 31 target roles were deleted at 2026-10-22 06:19:32 UTC by the same authenticated Salesforce user while this cleanup was running. This work did not issue a role-delete command.

Fourteen target roles remained at the final query. They had 27 assigned users: 25 inactive and 2 active. Four remaining target roles were children of other remaining target roles. User reassignment and further role deletion were not performed.
