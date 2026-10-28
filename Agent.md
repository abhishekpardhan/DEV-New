# Salesforce Development Instructions

This repository is a Salesforce DX project.

## Source of Truth

- Treat repository metadata as the primary source of truth.
- Inspect sfdx-project.json before making Salesforce metadata changes.
- Do not retrieve or deploy metadata unless necessary.
- Never modify unrelated metadata.
- Prefer targeted retrieval and deployment instead of retrieving/deploying the entire project.

## Salesforce Documentation

When platform behavior, API behavior, metadata, limits, security,
LWC, Flow, Agentforce, Data Cloud, or CLI behavior may have changed:

- Prefer current official Salesforce documentation.
- Prefer developer.salesforce.com and help.salesforce.com.
- Do not assume older Salesforce behavior is still current.
- Verify release-sensitive features before implementing them.

## Salesforce Architecture

Follow Salesforce Well-Architected principles.

Prefer:

1. Standard platform functionality
2. Declarative automation when appropriate
3. Apex when complexity, scale, transaction control, or maintainability requires it

Do not replace appropriate Apex with Flow merely for declarative-first compliance.

## Apex

All Apex must:

- Be bulkified.
- Support collections of records.
- Never execute SOQL or DML inside loops unless explicitly justified.
- Consider SOQL, DML, CPU, heap, callout and async governor limits.
- Use trigger-handler/service-layer patterns.
- Keep business logic out of trigger bodies.
- Prevent unwanted recursion.
- Handle partial failures when appropriate.
- Include meaningful test coverage.
- Test bulk operations and failure scenarios.

## Security

Always consider:

- record-level sharing
- CRUD
- field-level security
- user mode vs system mode
- least privilege

Do not assume `with sharing` enforces CRUD or FLS.

Prefer Permission Sets and Permission Set Groups for granting access.

Never expose secrets, passwords, access tokens, session IDs,
consumer secrets, certificates, or credentials in source code.

## LWC

Prefer:

1. Lightning Data Service / UI API
2. wire adapters
3. Apex only when necessary

Use Lightning base components where possible.

Handle loading, empty, success and error states.

## SOQL

- Never query inside loops.
- Query only fields required by the operation.
- Consider selectivity for large datasets.
- Consider high-volume logistics data when designing queries.

## Flow

Use Flow when automation is straightforward and maintainable.

Use Apex when:

- processing large datasets
- complex orchestration is required
- transaction control is important
- sophisticated error handling is required
- logic should be reusable across entry points

## Metadata

Before creating an object, field, permission set, Flow,
Lightning page, Apex class, LWC or other metadata:

1. Search the repository for an existing implementation.
2. Inspect naming conventions.
3. Identify dependencies.
4. Avoid creating duplicate metadata.

## Deployment

Never deploy directly to production without explicit approval.

Before deployment:

1. Review changed files.
2. Run relevant static analysis.
3. Run relevant Apex tests.
4. Prefer validation before production deployment.

Use targeted deployments whenever possible.

## Destructive Changes

Never delete Salesforce metadata without explicit approval.

## Working Style

For substantial changes:

1. Analyze existing implementation.
2. Explain proposed changes.
3. Identify impacted metadata.
4. Modify only required files.
5. Run validation/static analysis.
6. Run relevant tests.
7. Summarize modifications and remaining risks.



## Static Analysis

After creating or significantly modifying Apex, LWC, Flow,
or other supported Salesforce code:

Run Salesforce Code Analyzer when available.

Resolve high-severity security and correctness findings before considering
the task complete.

Do not blindly suppress static-analysis findings.
Explain why a suppression is justified.