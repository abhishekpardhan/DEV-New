# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Salesforce DX source-format project (single package dir `force-app`, no namespace, `sourceApiVersion` 67.0) mirroring a large production-style org: ~500 Apex classes, ~38 triggers, ~800 object folders, LWC/Aura, Flows, Agentforce (bots, genAi*, aiAuthoringBundles) and Data Cloud metadata. Default target org alias is **`Dev1`** (`.sf/config.json`).

`Agent.md` holds the team's standing Salesforce engineering rules (bulkification, security/CRUD/FLS, trigger-handler pattern, targeted deploys, no production deploys or metadata deletion without explicit approval, run Code Analyzer after significant changes). Follow it.

## Commands

```bash
# Targeted deploy / validate (preferred — never deploy the whole force-app)
sf project deploy start --source-dir force-app/main/default/classes/LeadAssignmentService.cls -o Dev1
sf project deploy start --manifest manifest/sf2-68.xml -o Dev1
sf project deploy validate --manifest manifest/sf2-68.xml -o Dev1 --test-level RunSpecifiedTests --tests LeadAssignmentServiceTest

# Retrieve specific metadata
sf project retrieve start --metadata ApexClass:LeadTriggerHandler -o Dev1

# Apex tests (run in the org)
sf apex run test --class-names LeadAssignmentServiceTest -o Dev1 --result-format human --code-coverage --wait 10
sf apex run test --tests LeadAssignmentServiceTest.testMethodName -o Dev1 --wait 10   # single method

# Anonymous Apex scripts (test-data / scenario scripts live in scripts/)
sf apex run --file scripts/create_stream_a_test_data.apex -o Dev1

# Static analysis
sf code-analyzer run --target force-app/main/default/classes/LeadAssignmentService.cls

# JS tooling (LWC/Aura only)
npm run lint
npm run test:unit                # sfdx-lwc-jest; no __tests__ exist yet
npm run prettier:verify
```

Husky pre-commit runs `lint-staged`: Prettier (with apex + xml plugins) on staged files, ESLint on aura/lwc JS, and related LWC Jest tests.

## Manifests

`manifest/` contains per-story deployment manifests (e.g. `sf2-45.xml`, `sf2-67.xml`, `sf2-68.xml`, `SF2_Lead_Assignment_Stream_A.xml`) — the `sf2-NN` names track work items. Create a new scoped manifest per story rather than editing `package.xml` (which is essentially empty) or `all_metadata.xml` (a full-org inventory, ~16.5k members; do not deploy it).

## Apex architecture

Two trigger styles coexist:

1. **Handler framework (newer code)** — trigger body is just `new XxxTriggerHandler().run();`. Handlers extend the virtual `TriggerHandler` class, override `beforeInsert`/`afterUpdate`/etc., and delegate to service classes. `TriggerHandler` provides loop-count recursion control and bypass via the hierarchy custom setting `Bypass_Setting__c.Bypass_Triggers__c` (semicolon-separated handler names) plus a static bypass API. Example: `LeadTrigger` → `LeadTriggerHandler` → `LeadEnrichmentService`, `LeadAssignmentService`, `LeadDuplicateService`, `LeadDropApprovalService`.
2. **Legacy `trg_*` triggers** — logic inline in the trigger, gated by `TriggerUtility.byPassTrigger` (static Boolean) and the custom label `System.Label.TriggerSwitch == 'On'`, calling `*TriggerHelper` classes. Large commented-out blocks are common; leave them unless asked.

Note there are two lead objects: standard `Lead` (`LeadTrigger`, handler framework — where current lead assignment/enrichment work happens) and custom `Lead__c` (`trg_Lead`, legacy). Confirm which one a task targets.

New trigger logic should use the handler framework. Tests use `TestDataFactory` for fixtures; HTTP callouts are tested with mock classes (e.g. `PincodeApiMock`). Integrations log through `Integration_Transaction__c` (`IntegrationTransactionHandler`), and much async work is in Queueable/Batch/Schedulable classes (`*Queueable`, `*Batch`, `*Job`).

## Non-source working folders

- `story-review/`, `permission-audit/`, `artifacts/`, `.lead-enrichment-validation/`: analysis, review evidence and isolated deployment payloads for past stories (lead sharing, permission-set regression, role cleanup). Their READMEs record decisions and "not yet deployed" status — read them before touching related metadata (sharing rules, Lead OWD, permission sets/PSGs, roles). E.g. lead-sharing must be deployed from its isolated payload with `--metadata-dir`, not from source.
- `scripts/permission-set-regression.ps1`: PowerShell audit of permission-set object/field/tab access against expected matrices; writes CSVs to `permission-audit/`.
- `skills/`: Salesforce-provided agent skill packs (each with `SKILL.md`) covering Apex, metadata deploy, Agentforce, Omni-Channel, etc. Consult the relevant one when a task falls in its domain.
