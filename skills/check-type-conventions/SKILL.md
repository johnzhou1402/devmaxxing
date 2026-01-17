---
name: check-type-conventions
description: Validate type conventions for money fields, enums, and GraphQL types. Use when adding new types, enums, or columns.
---

# Check Type Conventions

Validates that new types follow established codebase conventions.

## When to Run

- New GraphQL enum types added (`app/graphql/types/enum/`)
- New model enums added (`app/models/`)
- New columns added in migrations (`db/migrate/`)
- Changes to `db/schema.rb`

## Steps

### 1. Detect Type Changes

Check git diff for changes in:
```bash
git diff --name-only HEAD~1 | grep -E "(graphql/types/enum|models/|db/migrate)"
```

### 2. Check Money Field Conventions

**Rule**: Money fields must use `Types::Scalars::Decimal`, not Integer or Float.

**Check**: For any new/modified GraphQL fields representing money (USD amounts, earnings, volume, balance, etc.):
- Field type should be `Types::Scalars::Decimal`
- NOT `Integer` (loses decimal precision)
- NOT `Float` (floating point errors)

**How to verify**:
```bash
# Look for new money-related fields
grep -r "field :" <changed_files> | grep -E "(amount|price|fee|earning|balance|volume|revenue)"
```

**Flag**: "Field 'X' represents money but uses Integer/Float - use Types::Scalars::Decimal"

### 3. Check Model Enum Conventions

**Rule**: Model enums must use `.index_by(&:itself)` for string storage.

**Check**: For any new enum declarations in models:
```ruby
# CORRECT - stores as string
enum :status, %w(pending active completed).index_by(&:itself)
enum :business_type, BUSINESS_TYPES.index_by(&:itself)

# WRONG - stores as integer
enum :status, { pending: 0, active: 1, completed: 2 }
enum :annual_revenue, ANNUAL_REVENUE_OPTIONS  # if OPTIONS maps to integers
```

**How to verify**:
1. Find new enum declarations: `grep -r "enum :" <changed_model_files>`
2. Check if using `.index_by(&:itself)` pattern
3. If using a constant, check the constant definition

**Flag**: "Enum 'X' uses integer mapping - use `.index_by(&:itself)` for string storage"

### 4. Check GraphQL Enum Conventions

**Rule**: GraphQL enums should be built from model constants.

**Check**: For any new GraphQL enum types:
```ruby
# CORRECT - built from model constant
class BusinessTypes < Types::BaseEnum
  BusinessModels::BUSINESS_TYPES.each do |key|
    value key, key.titleize
  end
end

# WRONG - hardcoded values
class BusinessTypes < Types::BaseEnum
  value "saas", "SaaS"
  value "agency", "Agency"
end
```

**How to verify**:
1. Find new enum type files: `ls app/graphql/types/enum/`
2. Check if iterating over a model constant
3. Verify the constant exists and is the source of truth

**Flag**: "GraphQL enum 'X' has hardcoded values - build from model constant"

### 5. Check Column Type Conventions

**Rule**: Enum columns should be `string`, not `integer`.

**Check**: For any new columns in migrations:
```ruby
# CORRECT - string storage for enums
add_column :table, :status, :string
add_column :table, :business_type, :string

# WRONG - integer storage for enums
add_column :table, :status, :integer
add_column :table, :annual_revenue, :integer  # if this is an enum
```

**How to verify**:
1. Find new columns: `grep -r "add_column" <migration_files>`
2. Cross-reference with model to see if column is used as enum
3. Verify column type matches storage pattern

**Flag**: "Column 'X' is used as enum but has integer type - use string"

### 6. Compare Against Existing Patterns

**Rule**: New types should follow patterns of similar existing types.

**Steps**:
1. Identify 2-3 similar existing types in the codebase
2. Compare structure, naming, storage patterns
3. Flag any deviations

**Example**:
```bash
# If adding a new enum like annual_revenue, compare to:
# - business_type (in BotMetadata)
# - industry_type (in BotMetadata)
# Both use string storage with .index_by(&:itself)
```

**Flag**: "Type 'X' doesn't follow pattern of similar types (Y, Z)"

### 7. Report Results

Output format:
```
## Type Convention Check

✅ Money fields: All using Decimal
❌ Model enums: `annual_revenue` uses integer mapping
   → Fix: Change to `.index_by(&:itself)` pattern
❌ Column types: `annual_revenue` column is integer
   → Fix: Change migration to use :string type
✅ GraphQL enums: Built from model constants
```

## Quick Reference

| Type | Convention | Example |
|------|------------|---------|
| Money fields | `Types::Scalars::Decimal` | `field :amount, Types::Scalars::Decimal` |
| Model enums | `.index_by(&:itself)` | `enum :status, %w(...).index_by(&:itself)` |
| GraphQL enums | From model constants | `BusinessModels::X.each { \|k\| value k }` |
| Enum columns | `:string` type | `add_column :t, :status, :string` |

## Key Files

| Purpose | Location |
|---------|----------|
| Model enum patterns | `app/models/bot_metadata.rb` |
| GraphQL enum examples | `app/graphql/types/enum/business_types.rb` |
| Type constants | `app/models/concerns/business_models.rb` |
