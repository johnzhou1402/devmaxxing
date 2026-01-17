---
name: rails-console
description: Rails console guide for Whop production database queries
---

# Rails Console / Runner Guide

Essential knowledge for querying Whop's production database via Rails console or runner.

## Running Rails Commands

```bash
# From backend directory
cd /Users/johnzhou/whop-monorepo/main-whop-monorepo/backend

# Run a script file
mise exec -- rails runner tmp/my_script.rb

# Run inline Ruby (use single quotes to avoid escaping issues)
mise exec -- rails runner 'puts Bot.count'
```

## Critical Model Mappings

### Company is `Bot`

The "company" entity in Whop is stored as the `Bot` model:

```ruby
# WRONG - Company doesn't exist
company = Company.find_by(id: 123)

# CORRECT
bot = Bot.find_by(id: 123)
bot = Bot.find_by(tag: 'biz_X0DsFKNDBJ0o9K')
```

### Foreign Keys Use `bot_id` NOT `company_id`

```ruby
# WRONG
App.where(company_id: bot.id)
Experience.where(company_id: bot.id)

# CORRECT
App.where(bot_id: bot.id)
Experience.where(bot_id: bot.id)
```

### Common Models & Their Keys

| Model | Foreign Key to Company | Other Key Relationships |
|-------|----------------------|-------------------------|
| `Bot` | - | `tag: 'biz_...'` |
| `App` | `bot_id` | `tag: 'app_...'` |
| `Experience` | `bot_id` | `tag: 'exp_...'` |
| `LedgerAccount` | `resource_owner_id` + `resource_owner_type: 'Bot'` | `tag: 'ldgr_...'` |
| `Withdrawal` | via `ledger_account_id` | `tag: 'wthd_...'` |
| `AuthorizedApiKey` | polymorphic `resource_type`/`resource_id` | - |
| `Membership` | via experience | - |

### Polymorphic Associations

`LedgerAccount` uses polymorphic associations:

```ruby
# Find ledger account for a company (Bot)
ledger = LedgerAccount.where(
  resource_owner_type: 'Bot',
  resource_owner_id: bot.id
).first

# Count withdrawals
Withdrawal.where(ledger_account_id: ledger.id).count
```

## Tag vs ID

Every model has both:
- `id` - numeric, internal use only (never exposed to frontend)
- `tag` - string ID like `biz_X0DsFKNDBJ0o9K` (what frontend calls "id")

```ruby
# Find by numeric id (internal)
Bot.find(3732564)

# Find by tag (what frontend sends)
Bot.find_by(tag: 'biz_X0DsFKNDBJ0o9K')
```

## Rate Limiting Knowledge

### API Key Rate Limiting (GraphQL)

Located at: `backend/lib/middleware/api_v1_rate_limit_middleware.rb`

- Default: 600 RPM per endpoint per API key
- Key format: `RL|{minute}|{operation_name}|{api_key_resource_id}`
- **Important**: Session token requests bypass this rate limiter

### Rack::Attack (REST)

Located at: `backend/config/initializers/rack_attack.rb`

Only applies to:
- `/api/v2/customers/` - 5 req/sec
- OTP endpoints - 1 req/2sec

### Embedded Components Authentication

Embedded components use JWTs created from API keys:

1. Client calls `create_access_token` mutation with an API key
2. Server generates JWT (max 3 hour expiry) via `PermissionsManager::GenerateAuthorizedApiKeyJwt`
3. JWT header contains `kid: authorized_api_key.tag`
4. JWT carries original API key permissions

## Quick Investigation Template

```ruby
# tmp/investigate_company.rb
bot = Bot.find_by(tag: 'biz_XXXXXXXXXXXX')
puts "Bot: #{bot.tag} - #{bot.title}"

apps = App.where(bot_id: bot.id)
puts "Apps: #{apps.count}"

experiences = Experience.where(bot_id: bot.id)
puts "Experiences: #{experiences.count}"

ledger = LedgerAccount.where(resource_owner_type: 'Bot', resource_owner_id: bot.id).first
if ledger
  puts "Ledger: #{ledger.tag}"
  puts "Withdrawals: #{Withdrawal.where(ledger_account_id: ledger.id).count}"
end
```

## Common Errors

### "Unknown column 'company_id'"
Use `bot_id` instead.

### "uninitialized constant Company"
Use `Bot` model instead.

### "Trilogy::ProtocolError...replica"
You're on read-only prod DB - run `rails use_db:local` for writes.

### Bundler version errors
Use `mise exec -- rails ...` instead of `bundle exec rails ...`
