# Lead sharing - review and next steps

**If deploying package.xml produced ActionCadence/IqScore or other unrelated Lead-field errors, read [deployment-error-resolution.md](deployment-error-resolution.md). Use `--metadata-dir` with the isolated payload, not a source deployment of the full manifest.**

**All 34 rule XML definitions are prepared. Nothing is deployed.** Read approved-decisions.md for the user's confirmed changes.

1. Review **deployment-payload/package.xml**, **deployment-payload/sharingRules/Lead.sharingRules** and **deployment-payload/objects/Lead.object**. Group XML is in deployment-payload/groups. **lead-sharing-metadata.zip** contains that exact complete package: 19 groups, 34 rules and Lead OWD. A package manifest lists components; the separate XML files carry their definitions.
2. Review **source-change-review.md** for the before/after values and **file-change-review.md** for every full file path. **deployment-checksums.csv** identifies the exact artifacts you reviewed.
3. After target checks and explicit deployment approval, deploy the group-only manifest **manifest/lead-sharing-groups.xml**.
4. In **Setup -> Public Groups**, add the four exact **Roles** to each regional group using **membership-setup-checklist.csv**. Full steps are in **membership-setup-steps.md**. No Role-and-Subordinates memberships. Safexperience remains initially empty; preserve/report any unexpected live members.
5. After memberships are verified, validate/deploy **access-payload** (or its equivalent **lead-sharing-access.zip**) for Private/Private Lead OWD and the 34 rules. Future commands are in **dev-deployment-plan.md** and **qa-deployment-plan.md**. Do not deploy the full source directory or select CustomObject Lead from it.
6. Record actual deployment IDs, hashes and test evidence in **deployment-record.csv**. Wait for recalculation and test access. The CSV currently says NOT PERFORMED; no deployment success is claimed.

Memberships cannot be packaged in Group metadata XML. The metadata package and the separate membership setup together implement the model. Existing VH/Alliance groups, Lead fields/value sets, role hierarchy, permission metadata and the app are not deployed by this package. Required existing dependencies must therefore be present in each target org.

The approved inactive VH values are retained exactly; they do not match replacement active values automatically. Safexperience's group initially has no members, so its rule initially grants no user access through that group. Remaining live/external-team checks are in dependency-audit.md.
