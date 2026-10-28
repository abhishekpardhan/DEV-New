# Dev1 live verification - requirements are NOT complete

Verified org: Safexpress Private Limited; alias Dev1; org ID 00DC1000005VGonMAG; sandbox=True.
Latest deployment job: 0AfC1000009vuJdKAI; status=Succeeded; success=True; checkOnly=True; component errors=0.
Job completed at 2026-10-21T11:56:59.000Z (2026-10-21 17:26:59 Asia/Calcutta). This is validation, not an actual deployment.

The numberComponentsDeployed field reports 54 in this API result, but checkOnly=true means those components were validated without being saved. Per-component created/changed flags likewise describe the validation result, not committed changes.

| Requirement | Expected | Current evidence | Done? |
| --- | --- | --- | --- |
| C-02 app navigation | standard-Lead in safexpress2_0 | Previously verified in local XML; not queried live in this check | Local yes; live unverified |
| C-03 Lead internal OWD | Private | ReadWriteTransfer from live EntityDefinition | NO |
| C-03 Lead external OWD | Private | ReadWriteTransfer from live EntityDefinition | NO |
| C-04 regional groups | 18 groups | None of the exact proposed names exists in live Group query | NO |
| C-04 regional memberships | 4 direct Roles per group / 72 total | Parent public groups absent | NO |
| C-05 Safexperience group | Group exists, initially empty, hierarchy enabled | Exact group name absent in live query | NO |
| C-06 sharing rules | 18 regional + 14 VH + 1 Alliance + 1 Safexperience | All 34 passed this job without file-level errors, but check-only saved none; rule metadata not retrieved | Not applied by this job; full model incomplete |
| Existing VH/Alliance groups | Reuse 14 VH groups and Alliance | All 15 definitions exist live with DoesIncludeBosses=true; members not queried | Definitions yes; membership unverified |
| Role identities/hierarchy | Exact 72 roles; retain approved GJT hierarchy | Local role evidence only in this check | Live verification outstanding |
| UST1 / UST4 / UST8 / Dev 5 | Dependencies and persona access accepted | No new acceptance evidence | Outstanding |
| Visibility testing | Positive/negative access matrix after recalculation | No runtime tests performed | Outstanding |

## All XML contents
all-package-components.md/csv lists each of the 54 manifest members and its exact full payload file path. all-package-files.csv lists all 22 physical files, including package.xml. No field, validation rule, profile, permission set, Apex, Flow, role or app component is in the isolated package.

## Next steps
1. Use the reviewed group-only deployment command (without --dry-run) when ready to perform the actual approved deployment.
2. Add and verify the four direct Role members in each regional group using membership-setup-checklist.csv. Keep hierarchy access enabled and Safexperience initially empty; review unexpected existing members rather than deleting them.
3. Validate and then actually deploy access-payload for Lead OWD and all 34 rules. The actual deployment command omits --dry-run. See ../dev-deployment-plan.md for the exact phase commands.
4. Confirm an actual job has success=true AND checkOnly=false, verify OWD/groups/rules in the org, wait for recalculation and run persona access tests.
5. Confirm external-team dependencies and repeat QA-specific checks before promotion.

Only read-only deployment-report and SOQL queries were run for this audit. No metadata retrieval, deployment, validation job, data mutation or Setup update was executed. The live checks establish the current absence of the proposed groups and unchanged OWD; they do not claim that every unrelated previous org operation was inspected.