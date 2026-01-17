---
name: checklist-manifesto
description: Run parallel quality checks before pushing code
---

# Checklist Manifesto

Pre-push quality gate that runs checks in parallel via subagents.

## Usage

- `/checklist-manifesto` - Run all checks on staged/committed changes

## Execution Steps

### 1. Get Changed Files

First, identify what files have changed:

```bash
git diff --name-only HEAD~1
```

### 2. Determine Which Checks Apply

Based on changed files, determine which checks to run:

| If changes include... | Run check |
|-----------------------|-----------|
| `backend/app/graphql/types/**/*.rb` | check-type-conventions, check-schema-regen |
| `backend/app/models/**/*.rb` with enums | check-type-conventions |
| `db/migrate/*.rb` with new columns | check-type-conventions |
| `backend/app/services/graphql_rest_proxy/fragments/*.graphql` | check-related-specs |
| `backend/app/graphql/types/output/*.rb` | check-related-specs |
| Ticket mentions API docs | check-api-docs |

### 3. Run Applicable Checks in Parallel

For each applicable check, spawn a sub-agent using the Task tool:

```
Task tool with subagent_type: "general-purpose"
prompt: "Run the check-type-conventions skill on these changed files: [files]"
```

Run all applicable checks in parallel by calling multiple Task tools in a single response.

### 4. Collect Results

Wait for all sub-agents to complete and collect their results.

### 5. Report Summary

Output a combined summary:

```
## Pre-Push Quality Check Results

### check-type-conventions
✅ Money fields: All using Decimal
✅ Model enums: Using .index_by(&:itself)
✅ Column types: Enum columns are strings

### check-related-specs
✅ graphql_resources specs: 45 passed
✅ type specs: 12 passed

### check-api-docs
✅ V1 API - schema will auto-update

### check-schema-regen
✅ CI will auto-commit schema changes

---
All checks passed! Safe to push.
```

Or with issues:

```
## Pre-Push Quality Check Results

### check-type-conventions
❌ Model enum `annual_revenue` uses integer mapping
   → Fix: Use `.index_by(&:itself)` for string storage

### check-related-specs
⏭️ Skipped (no relevant changes)

---
1 issue found. Please fix before pushing.
```

## Sub-Skills Reference

This skill orchestrates the following sub-skills:

| Skill | Purpose | When to Run |
|-------|---------|-------------|
| `check-type-conventions` | Validate money fields, enums, column types | GraphQL types, models, migrations changed |
| `check-related-specs` | Run specs affected by your changes | GraphQL fragments, output types changed |
| `check-api-docs` | Verify API documentation approach | Ticket mentions API docs |
| `check-schema-regen` | Ensure schema is regenerated | GraphQL types changed |

## Manual Invocation of Sub-Skills

You can also run individual checks:

- `/check-type-conventions` - Just type/enum validation
- `/check-related-specs` - Just related spec execution
- `/check-api-docs` - Just API docs verification
- `/check-schema-regen` - Just schema regeneration check
