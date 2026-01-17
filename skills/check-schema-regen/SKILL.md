---
name: check-schema-regen
description: Verify GraphQL schema was regenerated after type changes. Use when modifying GraphQL types.
---

# Check Schema Regeneration

Ensures GraphQL schema is regenerated after modifying type files.

## Why This Matters

GraphQL types define the API contract. When types change, the schema files must be regenerated for:
- TypeScript/Swift codegen to pick up changes
- API documentation to update
- Frontend type safety

## Steps

### 1. Detect GraphQL Type Changes

```bash
git diff --name-only HEAD~1 | grep -E "backend/app/graphql/types/"
```

### 2. Check if Schema Was Updated

If GraphQL types were modified, verify schema regeneration:

**Automatic (CI):**
- Look for `[CI] Update GraphQL schema` commit
- This happens automatically on push

**Manual (if needed):**
```bash
cd backend
bundle exec rake graphql:schema:dump
bundle exec rake graphql_public:schema:dump
```

### 3. Key Schema Files

| Purpose | Location |
|---------|----------|
| Internal schema | `backend/public/graphql/internal/configured_schema.graphql` |
| Public schema | `backend/public/graphql/public/configured_schema.graphql` |
| GraphQL types | `backend/app/graphql/types/` |

### 4. Verify Changes Propagate

After schema regeneration:
1. Frontend codegen runs automatically
2. iOS/Android `make api` picks up changes
3. V1 REST docs update hourly

### 5. Report Results

```
## Schema Regeneration Check

Modified GraphQL types:
- app/graphql/types/enum/annual_revenue_ranges.rb (new)
- app/graphql/mutations/register_company.rb

Schema status:
✅ CI will auto-commit schema update on push
✅ Or manually run: bundle exec rake graphql:schema:dump
```

Or if schema is out of sync:

```
## Schema Regeneration Check

⚠️ Modified GraphQL types but schema not updated

Run:
cd backend && bundle exec rake graphql:schema:dump

Then commit the updated schema files.
```

## Common Scenarios

### New Enum Type
When adding a new enum (like `AnnualRevenueRanges`):
1. Create type file in `app/graphql/types/enum/`
2. Use in mutation/query arguments
3. Schema auto-regenerates on CI

### Modified Output Type
When changing fields on output types:
1. Edit `app/graphql/types/output/*.rb`
2. Schema auto-regenerates
3. Frontend codegen updates types

### Flag Format

**Flag**: "Modified GraphQL types but schema wasn't regenerated - run `bundle exec rake graphql:schema:dump`"
