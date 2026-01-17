---
name: check-related-specs
description: Identify and run specs that may be affected by your changes but aren't in the changed files.
---

# Check Related Specs

Finds and runs specs that test functionality you modified, even if the spec files themselves weren't changed.

## Why This Matters

`bin/test-changes` only runs specs for files you modified. But other spec files may test the same functionality through integration tests. This check catches those.

## Steps

### 1. Detect Changed Files

```bash
git diff --name-only HEAD~1
```

### 2. Map Changes to Related Specs

| If you changed... | Also run these specs... |
|-------------------|------------------------|
| `app/services/graphql_rest_proxy/fragments/*.graphql` | `rspec spec/graphql/graphql_resources/` |
| `app/graphql/types/output/*.rb` | `rspec spec/graphql/` for related type specs |
| `app/graphql/types/enum/*.rb` | `rspec spec/graphql/` for types using that enum |
| `app/services/**/*.rb` | Specs for mutations/queries calling that service |
| REST API changes | `rspec spec/graphql/graphql_resources/` |

### 3. Check if Related Specs Were Run

Ask: "Did you run the related specs?"

If not, provide the command:
```bash
# For GraphQL REST proxy changes
bundle exec rspec spec/graphql/graphql_resources/

# For output type changes
bundle exec rspec spec/graphql/types/

# For service changes
bundle exec rspec spec/services/<service_name>/
```

### 4. Run the Specs

Execute the identified spec commands and report results.

### 5. Report Results

```
## Related Specs Check

Changed files:
- app/services/graphql_rest_proxy/fragments/user.graphql
- app/graphql/types/output/user_type.rb

Related specs to run:
- spec/graphql/graphql_resources/ (REST proxy)
- spec/graphql/types/user_type_spec.rb

Results:
✅ graphql_resources: 45 examples, 0 failures
✅ user_type_spec: 12 examples, 0 failures
```

## Common Patterns

### GraphQL REST Proxy

When modifying fragments in `app/services/graphql_rest_proxy/fragments/`:
```bash
bundle exec rspec spec/graphql/graphql_resources/
```

### Output Types

When modifying `app/graphql/types/output/X_type.rb`:
```bash
bundle exec rspec spec/graphql/types/X_type_spec.rb
# Also check for integration specs
bundle exec rspec spec/graphql/queries/ -e "X"
```

### Services

When modifying `app/services/X/`:
```bash
bundle exec rspec spec/services/X/
# Also check mutations that use this service
grep -r "X::" app/graphql/mutations/ | cut -d: -f1 | sort -u
```

## Flag Format

**Flag**: "Modified REST API fragment but didn't run graphql_resources specs"
**Flag**: "Modified output type but didn't run related type specs"
