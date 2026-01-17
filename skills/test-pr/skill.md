---
name: test-pr
description: Set up local environment to test a PR with production-like data
---

# Test PR Locally

Set up a complete local testing environment for any PR, including cloning production data and configuring all necessary services.

## Usage

- `/test-pr <PR_URL>` - Set up environment to test a specific PR
- `/test-pr 705` - Can also use just the PR number

## Prerequisites

- Access to production database (read-only)
- Local Docker/Orbstack running for MySQL
- GitHub CLI (`gh`) authenticated

## Steps

### 1. Sync Local Schema with Production

Before cloning production data, ensure your local database schema is up to date. Missing columns during import indicate you need to pull latest main.

```bash
cd /path/to/whop-monorepo

# Stash any current changes if needed
git stash

# Pull latest main and run migrations
git checkout main
git pull origin main
cd backend
bin/rails db:migrate

# Return to PR branch (we'll checkout the PR later)
git stash pop  # if you stashed
```

This ensures your local schema matches production, preventing "Unknown column" errors during data import.

### 2. Analyze the PR

First, understand what the PR changes and what data/state is needed to test it:

```bash
# Get PR details
gh pr view <number> --json title,body,files,state

# Get the full diff
gh pr diff <number> --patch
```

**Identify:**
- Which models/tables are affected
- What state/conditions need to exist to test the feature
- Which services (backend, frontend, embeddable-components) are involved

### 3. Find a Suitable Bot to Clone

Connect to prod (read-only) and find a small bot that matches or is close to the test requirements:

```bash
cd backend
bin/rails use_db:prod
```

**Query template for finding bots:**

```ruby
bin/rails runner '
# Customize this query based on PR requirements
# Example: Find bot with active recurring subscriptions
Bot.joins(:memberships)
   .where(memberships: { status: "active" })
   .where.not(memberships: { plan_id: nil })
   .distinct
   .find_each do |bot|
     receipt_count = bot.receipts.count
     next if receipt_count > 100  # Keep it small

     puts "BOT_ID=#{bot.tag}"  # Use the tag (biz_xxx) as BOT_ID
     puts "Title: #{bot.title}"
     puts "Receipts: #{receipt_count}"
     puts "Memberships: #{bot.memberships.count}"
     break
   end
'
```

**Common query patterns:**

| Test Scenario | Query Filter |
|---------------|--------------|
| Canceled subscriptions | `memberships: { cancel_at_period_end: true }` |
| Active subscriptions | `memberships: { status: "active" }` |
| With receipts | `.joins(:receipts)` |
| With payouts | `.joins(:payout_account)` |
| Platform/connected accounts | `.where.not(parent_bot_id: nil)` |

### 4. Clone Bot Data to Local

Once you have a BOT_ID (which is the tag like `biz_xxx`):

```bash
cd backend

# Switch back to local DB first
bin/rails use_db:local

# Clone the bot (this pulls from prod and imports to local)
SCENARIO=bot BOT_ID=<bot_tag> bin/rails db:dump:pull
```

This command:
- Connects to prod read-only
- Exports the bot and all related data (memberships, receipts, users, etc.)
- Imports into your local MySQL database

### 5. Modify Local Data for Test Scenario

If the cloned data doesn't exactly match the test requirements, modify it locally:

```bash
cd backend
bin/rails c

# Example: Set a membership to cancel_at_period_end
bot = Bot.find_by(tag: "<bot_id>")  # bot_id is the tag like biz_xxx
membership = Membership.joins(:access_pass).where(access_passes: { bot_id: bot.id }).where(status: "active").first
membership.update!(cancel_at_period_end: true)

# Example: Find the user who owns this membership (for login)
user = membership.user
puts "Login as: #{user.tag} (#{user.email})"
```

### 6. Configure Local Environment Files

**Backend** (`backend/.env.development.local`):
```bash
# Should already be set by use_db:local, but verify:
PS_ENV_TO_USE=local
```

**Frontend** (`frontend/apps/core/.env.development.local`):
```env
NEXT_PUBLIC_API_BASE="http://localhost:3000/api/v3"
NEXT_PUBLIC_GRAPH_BASE="http://localhost:3000/graphql"
NEXT_PUBLIC_WS_BASE="ws://localhost:5001"
```

**Embeddable Components** (`developer-platform/apps/embeddable-components/.env.development.local`):
```env
NEXT_PUBLIC_GRAPHQL_ENDPOINT="http://localhost:3005/graphql"
```

### 7. Apply Local Development Code Changes

**IMPORTANT:** Apply these changes to enable local development. These are required fixes - make them as part of your test setup.

**File: `backend/app/services/auth/determine_auth_context.rb`** (around line 168):
```ruby
# Change:
user_ident.strip!
# To:
user_ident = user_ident.strip
```
This fixes frozen string error when using `CURRENT_USER=1`.

**File: `developer-platform/apps/embeddable-components/codegen.ts`** (line 18):
```typescript
// Change:
"https://data.whop.com/graphql/private/configured_schema.graphql"
// To:
"http://localhost:3005/graphql/private/configured_schema.graphql"
```

**File: `developer-platform/apps/embeddable-components/graphql/execute.ts`** (line 66):
```typescript
// Change:
url: endpoint ?? "https://components-api.whop.com/graphql",
// To:
url:
  endpoint ??
  process.env.NEXT_PUBLIC_GRAPHQL_ENDPOINT ??
  "https://components-api.whop.com/graphql",
```

**Note:** These changes are for local testing only. Revert before committing unrelated changes.

### 8. Checkout the PR Branch

```bash
cd /path/to/whop-monorepo

# Fetch and checkout PR
git fetch origin pull/<number>/head:test-pr-<number>
git checkout test-pr-<number>
```

### 9. Start Services

**Terminal 1 - Backend:**
```bash
cd backend

# Ensure you're using local DB (not prod!)
bin/rails use_db:local

# Simple case - just Rails server with auth bypass
CURRENT_USER=1 rails s

# OR if you need background jobs, ClickHouse analytics, or PubSub:
CURRENT_USER=1 bin/dev
```

**When to use which:**
| Command | Use when... |
|---------|-------------|
| `CURRENT_USER=1 rails s` | Most testing - bypasses auth, fast startup |
| `CURRENT_USER=1 bin/dev` | Need Sidekiq (background jobs), ClickHouse (analytics), or PubSub |

The `CURRENT_USER=1` env var bypasses authentication entirely (development only).

**Terminal 2 - Frontend:**
```bash
cd frontend/apps/core
pnpm dev
```

**Terminal 3 - Embeddable Components (if needed):**
```bash
cd developer-platform/apps/embeddable-components
pnpm dev
```

### 10. Provide a Test Plan

After setting up the environment, **always give the user a clear test plan** that includes:

1. **Test URL**: The exact localhost URL to visit (e.g., `http://localhost:8004/dashboard/biz_xxx/developer/webhooks`)
2. **Steps to reproduce**: Numbered steps of exactly what to click/do
3. **Expected behavior**: What they should see if the PR is working correctly
4. **What changed**: Before vs after comparison if it's a UI change

**Example test plan format:**
```
## Test Plan

**URL:** http://localhost:8004/dashboard/biz_xxx/settings

**Steps:**
1. Navigate to the URL above
2. Click "Create webhook" button
3. Fill in the endpoint URL field
4. Look for the "Connected account events" section

**Expected behavior:**
- You should see a toggle switch (not a checkbox) labeled "Connected account events"
- Below it should say "When enabled, this webhook will also receive events from your connected accounts"
- Toggling it on/off should work smoothly

**Before (old behavior):**
- Checkbox labeled "Submerchant events" with a tooltip icon

**After (new behavior):**
- Switch component labeled "Connected account events" with inline description
```

### 11. Cleanup

After testing:

```bash
# Switch back to your original branch
git checkout <original-branch>

# Revert local code changes (don't commit them!)
git checkout -- backend/app/services/auth/determine_auth_context.rb
git checkout -- developer-platform/apps/embeddable-components/codegen.ts
git checkout -- developer-platform/apps/embeddable-components/graphql/execute.ts
```

## Common Test Scenarios

### Billing Portal Features
Since auth is not set up for the billing portal locally, use `CURRENT_USER=1` to bypass auth entirely:

```bash
# Start backend with auth bypass
CURRENT_USER=1 rails s
```

If you need specific user data (memberships, payout settings, etc.), clone from prod first:

1. Find a suitable user in prod:
```ruby
bin/rails use_db:prod
user = User.find_by(email: "john.zhou@whop.com")
puts user.tag  # e.g., user_xxx
```

2. Clone their data:
```bash
bin/rails use_db:local
# Clone using the db:dump:pull task if needed
```

### Billing/Subscription Features
- Clone bot with active subscriptions
- Modify membership state as needed (cancel_at_period_end, status, etc.)
- Test as the user who owns the membership

### Payout Features
- Clone bot with payout_account configured
- May need to clone connected payout tokens

### Platform/Connected Account Features
- Clone a parent bot that has child bots
- Or clone a child bot with its parent

### Resolution Center Features
- Clone bot with resolutions
- May need to modify resolution status locally

## Troubleshooting

**"Connection refused" errors:**
- Make sure Orbstack/Docker is running
- Run `bin/up` in backend folder

**"Read-only database" errors:**
- You're still connected to prod: run `bin/rails use_db:local`

**"User not found" errors:**
- The cloned data might not include the user
- Try a different bot or manually create the user

**Frontend can't connect to backend:**
- Check `.env.development.local` has correct ports
- Make sure backend is running on expected port (usually 3000)

**GraphQL schema errors (e.g., "Cannot query field X on type Y"):**
- Rebuild the gql package with local schema: `cd frontend/packages/gql && CI=true pnpm build`
- The `CI=true` is required to use the local committed schema file instead of fetching from remote
