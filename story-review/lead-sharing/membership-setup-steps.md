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