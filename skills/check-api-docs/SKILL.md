---
name: check-api-docs
description: Verify API documentation approach based on API version (V1/V2/V5). Use when ticket mentions API docs.
---

# Check API Docs

Ensures correct approach for API documentation updates based on which API version is involved.

## API Version Architecture

| Version | Implementation | How to Update |
|---------|---------------|---------------|
| **V1** | GraphQL proxy | Change GraphQL schema → docs auto-generate |
| **V2** | Grape REST | Manual (rarely needed) |
| **V5** | Rails controllers | Manual (rarely needed) |

## Steps

### 1. Identify API Version

Check the ticket/task to determine which API version is involved.

**V1 indicators**:
- Mentions GraphQL
- References `/api/v1/` endpoints
- Talks about REST responses that mirror GraphQL

**V2 indicators**:
- Mentions Grape
- References `/api/v2/` endpoints
- Talks about legacy endpoints

**V5 indicators**:
- Mentions Rails controllers
- References `/api/v5/` endpoints

### 2. V1 Update Flow (Most Common)

For V1 (GraphQL-based) API docs:

1. **Modify GraphQL types** in `backend/app/graphql/`
2. **CI auto-commits schema**: Look for `[CI] Update GraphQL schema` commit
3. **Hourly workflow** auto-regenerates docs

**No manual doc updates needed for V1!**

GraphQL changes propagate to V1 REST automatically via `GraphqlRestProxy`.

### 3. V2/V5 Update Flow (Rare)

If ticket requires V2 or V5 changes:

**Flag**: "Ticket mentions V2/V5 docs - these require manual updates, confirm scope"

V2/V5 require:
- Manual endpoint changes
- Manual serializer updates
- Consider escalating if unsure

### 4. Verify Key Files

| Purpose | Location |
|---------|----------|
| GraphQL types | `backend/app/graphql/types/` |
| V1 REST mappings | `backend/app/services/graphql_rest_proxy/api_definition.rb` |
| V1 fragments | `backend/app/services/graphql_rest_proxy/fragments/*.graphql` |
| Schema output | `backend/public/graphql/*/configured_schema.graphql` |

### 5. Report Results

```
## API Docs Check

API Version: V1 (GraphQL-based)

✅ Approach: Modify GraphQL types, docs auto-generate
✅ Schema will be auto-committed by CI
✅ No manual doc updates needed

Changed files:
- app/graphql/types/output/user_type.rb

This will automatically update:
- V1 REST endpoint: GET /api/v1/users/:id
```

Or for V2/V5:

```
## API Docs Check

⚠️ API Version: V2 (Grape REST)

This requires manual updates:
- Endpoint: app/api/v2/users.rb
- Serializer: app/serializers/v2/user_serializer.rb

Please confirm scope with team lead.
```

## Quick Reference

### V1 Auto-Update Chain

```
GraphQL type change
       ↓
CI commits schema
       ↓
Hourly workflow
       ↓
Docs regenerated
```

### When to Escalate

- Ticket explicitly mentions V2 or V5
- Need to add entirely new endpoints (not just modify existing)
- Breaking changes to API contracts
