# PR Feedback History

## 2026-01-07

### PR #455 - Cache plaid balances
**From**: diegofigueroa
**Category**: Process
**File**: N/A

> "you need to run the db migrations (`rails db:migrate`) so that the schema.rb file gets updated and the planetscale DRs get created by CI"

**Lesson**: Always run migrations locally before pushing to ensure schema.rb is updated and PlanetScale deploy requests are created by CI.

---

### PR #455 - Cache plaid balances
**From**: jacksonhuether
**Category**: Architecture
**File**: backend/db/migrate/20260105225639_add_plaid_balance_to_payout_tokens.rb

> "We should store as a decimal like we do all of the other fields in our DB. Precision 10 scale 2."

**Lesson**: Financial data should always use decimal type (precision 10, scale 2), not bigint for cents or floats.

---

### PR #420 - Include transfer volumes in connected account volumes
**From**: jacksonhuether
**Category**: Architecture
**File**: N/A

> "Should make it a separate column if you want it to be aggregate of the both. Because there are a lot of places that are using the total_memberships_earnings and expecting it to just be GMV. Also should use ClickHouse for executing the query instead of quering MySQL directly. Also need to add a trigger to invalidate the cache whenever a new transfer is made."

**Lesson**: When adding new metrics that combine existing data, create a new column rather than modifying existing ones. Use ClickHouse for aggregates and ensure cache invalidation on data changes.

---

### PR #420 - Include transfer volumes in connected account volumes
**From**: jacksonhuether
**Category**: Architecture
**File**: backend/app/models/credit_transaction_transfer.rb

> "you don't need this you can just use credit_transactions and filter by credit_type = \"inner_platform_transfer\""

**Lesson**: Before adding new ClickHouse table mirrors, check if existing tables already have the data you need.

---

### PR #420 - Include transfer volumes in connected account volumes
**From**: jacksonhuether
**Category**: Naming
**File**: backend/db/migrate/20260105200000_add_total_earnings_with_transfers_to_bots.rb

> "Just make this a decimal precision 10 scale 2. also total_earnings_with_transfers_in_usd"

**Lesson**: Column names for USD amounts should have `_in_usd` suffix for clarity. Use decimal type for financial data.

---

### PR #420 - Include transfer volumes in connected account volumes
**From**: jacksonhuether
**Category**: Logic
**File**: backend/app/workers/backfill_manager/backfill_bot_total_earnings_with_transfers_worker.rb

> "We should backfill all bots not just child ones. Also i would increase the throttle to 100 per second."

**Lesson**: Backfill workers should cover all records, not just a subset. Increase throttle for faster processing.

---

### PR #495 - Zfellows accelerator program
**From**: g-delmo
**Category**: UX
**File**: N/A

> "since you will have reduced fees, i would add something here on this fee breakdown that shows we are waiving certain fees (or giving you a discount) because you're within your first $500k of revenue thanks to our accelerator program. think about how people will screenshot that and share it as well so imp to make it sexy"

**Lesson**: Think about the marketing/sharing potential of UI elements. Fee breakdowns are screenshot-worthy moments.

---

### PR #495 - Zfellows accelerator program
**From**: jacksonhuether
**Category**: Logic
**File**: backend/app/services/companies/manage_feature.rb

> "Should add logic to remove fee override once they hit the 500k."

**Lesson**: Don't forget cleanup logic for temporary states. Accelerator benefits need automatic graduation.

---

### PR #495 - Zfellows accelerator program
**From**: jacksonhuether
**Category**: Architecture
**File**: backend/app/services/accelerator_program/graduate.rb

> "Use manage feature service"

**Lesson**: Reuse existing services for feature management rather than creating custom logic.

---

## 2026-01-12

### PR #938 - Add rails-console skill for team database queries
**From**: sharkey11
**Category**: Architecture
**File**: N/A

> "Hey John! Great content here - this tribal knowledge is super valuable. I pulled this into my PR (#924) with a small restructure to match the pattern we're establishing: 1. Model mappings & query patterns → internal-docs/engineering/data/schema.mdx (source of truth) 2. Thin skill wrapper → .ai/skills/rails-console/SKILL.md (points to docs). The pattern is: internal docs hold the authoritative content, skills are thin wrappers that reference them. This way the content is discoverable both in the wiki and by AI agents."

**Lesson**: When adding new AI skills/documentation, follow the established pattern: authoritative content lives in `internal-docs/`, while skills are thin wrappers that reference those docs. This ensures content is discoverable both in the wiki (for humans) and by AI agents.

---
