#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}┌─────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🌙 Claude Skills Setup             │${NC}"
echo -e "${BLUE}└─────────────────────────────────────┘${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# Step 1: Check prerequisites
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Checking prerequisites...${NC}"
echo ""

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI (gh) not found${NC}"
    echo ""
    echo "  Install with: brew install gh"
    echo "  Then run: gh auth login"
    echo ""
    exit 1
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI not authenticated${NC}"
    echo ""
    echo "  Run: gh auth login"
    echo "  Then re-run this setup."
    echo ""
    exit 1
fi

GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓ GitHub CLI authenticated as @${GH_USER}${NC}"

# Check Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ Claude Code not found${NC}"
    echo ""
    echo "  Install with: npm install -g @anthropic-ai/claude-code"
    echo "  Then re-run this setup."
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Claude Code installed${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# Step 2: Ask about email notifications
# ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Email Configuration${NC}"
echo ""
echo "Would you like to receive email digests when you run /end-day?"
echo "This sends a nicely formatted summary to your inbox."
echo ""
read -p "Enable email digests? (y/n): " ENABLE_EMAIL
echo ""

RESEND_KEY=""
USER_EMAIL=""

if [[ "$ENABLE_EMAIL" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}We'll use Resend to send emails (free tier: 100 emails/day)${NC}"
    echo ""
    echo "To get your API key:"
    echo "  1. Go to https://resend.com/signup"
    echo "  2. Create a free account"
    echo "  3. Go to API Keys → Create API Key"
    echo "  4. Copy the key (starts with 're_')"
    echo ""
    echo -e "${YELLOW}Tip: Set up usage alerts at https://resend.com/settings/alerts${NC}"
    echo "     to get notified if you approach the limit."
    echo ""

    read -p "Resend API key (or press enter to skip): " RESEND_KEY

    if [[ -n "$RESEND_KEY" ]]; then
        read -p "Your email address: " USER_EMAIL

        if [[ -z "$USER_EMAIL" ]]; then
            echo -e "${RED}Email required if using Resend. Skipping email setup.${NC}"
            RESEND_KEY=""
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────
# Step 3: Create directories
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Creating directories...${NC}"

mkdir -p ~/.claude/skills/end-day
mkdir -p ~/devmaxxing/standup
mkdir -p ~/devmaxxing/reviews/daily

echo -e "${GREEN}✓ Created ~/.claude/skills/end-day/${NC}"
echo -e "${GREEN}✓ Created ~/devmaxxing/standup/${NC}"
echo -e "${GREEN}✓ Created ~/devmaxxing/reviews/daily/${NC}"

# ─────────────────────────────────────────────────────────────
# Step 4: Write config file
# ─────────────────────────────────────────────────────────────
if [[ -n "$RESEND_KEY" && -n "$USER_EMAIL" ]]; then
    cat > ~/.claude/skills/end-day/config.json << EOF
{
  "resend_api_key": "${RESEND_KEY}",
  "email_to": "${USER_EMAIL}",
  "email_from": "onboarding@resend.dev"
}
EOF
    echo -e "${GREEN}✓ Created config.json with email settings${NC}"
else
    cat > ~/.claude/skills/end-day/config.json << EOF
{
  "resend_api_key": "",
  "email_to": "",
  "email_from": "onboarding@resend.dev"
}
EOF
    echo -e "${GREEN}✓ Created config.json (email disabled)${NC}"
fi

# ─────────────────────────────────────────────────────────────
# Step 5: Write skill file
# ─────────────────────────────────────────────────────────────
cat > ~/.claude/skills/end-day/SKILL.md << 'SKILL_EOF'
---
name: end-day
description: Save PR feedback for all branches you touched today (or yesterday with "ystd")
---

# End Day

Generate standup summary, save PR feedback, and email yourself a digest.

## Usage

- `/end-day` - today's PRs
- `/end-day ystd` or `/end-day yesterday` - yesterday's PRs
- `/end-day 2026-01-05` - specific date

## Steps

### 1. Determine the target date

- No argument → today's date
- "ystd" or "yesterday" → yesterday's date
- "YYYY-MM-DD" → that specific date

### 2. Get PRs you worked on that date from GitHub

```bash
gh pr list --author @me --state all --limit 50 --json number,title,headRefName,updatedAt,state,isDraft,reviewDecision,url \
  --jq '.[] | select(.updatedAt | startswith("YYYY-MM-DD"))'
```

### 3. Generate Standup Summary

For each PR, gather context and write a leadership-friendly summary:

```bash
# PR details
gh pr view <number> --json title,body,state,isDraft,reviewDecision,statusCheckRollup

# Commits on this branch
git log main..<branch> --no-merges --oneline
```

**Status mapping:**

- `state=MERGED` → 🟢 **Merged**
- `state=CLOSED` → 🔴 **Closed**
- `isDraft=true` → ⚪ **Draft**
- `reviewDecision=CHANGES_REQUESTED` → 🟠 **Changes Requested**
- `reviewDecision=APPROVED` + CI passing → 🟢 **Ready to Merge**
- `reviewDecision=REVIEW_REQUIRED` → 🟡 **Ready for Review**

**For each PR, write:**

- **What**: 1-2 sentence business impact (not technical details)
- **Status**: From mapping above
- **Next**: What happens next?

**Writing style:**

- Lead with impact, not implementation
- No jargon - your manager should understand it
- Bad: "Added a migration to store plaid balances"
- Good: "Creators can now see their real bank balance when setting up payouts"

Write to `~/devmaxxing/standup/YYYY-MM-DD.md`

### 4. Save PR Feedback

For each PR with human review comments:

```bash
# General reviews
gh pr view <number> --json reviews,comments

# Inline code comments
gh api repos/{owner}/{repo}/pulls/<number>/comments
```

**Filter to human reviewers only** (ignore bots: vercel, linear, github-actions, sentry, cursor, seer)

For each human comment, extract and analyze:

- Reviewer name
- File path and line numbers (if inline)
- Comment text
- **Intention**: What is the reviewer really asking for?
- **Category**: Style | Logic | Performance | Security | Testing | Naming | Architecture
- **Lesson**: What general principle can you learn?

Write to `~/devmaxxing/reviews/daily/YYYY-MM-DD.md`

### 5. Send Email Digest

Read config from `~/.claude/skills/end-day/config.json`. If `resend_api_key` is empty, skip email.

```json
{
  "resend_api_key": "re_xxx",
  "email_to": "you@email.com",
  "email_from": "onboarding@resend.dev"
}
```

Send email via Resend API:

```bash
curl -X POST 'https://api.resend.com/emails' \
  -H 'Authorization: Bearer <resend_api_key>' \
  -H 'Content-Type: application/json' \
  -d '{
    "from": "<email_from>",
    "to": "<email_to>",
    "subject": "🌙 End of Day: YYYY-MM-DD",
    "html": "<email_content>"
  }'
```

**Email style:**

- Use emojis liberally (🌙 🟢 🟡 🟠 🔴 💬 💡 ⏳ 📝)
- Casual, easy-to-read tone
- Status colors: 🟢 Merged, 🟡 Ready for Review, 🟠 Changes Requested, 🔴 Closed
- Card-style layout with rounded backgrounds for each PR
- Quote blocks for reviewer comments
- "💡 Takeaway:" for lessons learned

**Email structure:**

```text
🌙 End of Day: [Day of week], [Date]

📋 What I worked on (N PRs)
  - [emoji] PR Title
    Status: ...
    [casual 1-2 sentence summary]
    [next step indicator]

💬 Feedback I got (N comments)
  - [reviewer] on PR #X
    "[quoted comment]"
    💡 Takeaway: [lesson]
```

### 6. Report Summary

Print to terminal:

```text
End of day complete for YYYY-MM-DD

Standup:
  - N PRs summarized
  - Saved to ~/devmaxxing/standup/YYYY-MM-DD.md

Feedback:
  - N human comments saved
  - Saved to ~/devmaxxing/reviews/daily/YYYY-MM-DD.md

Email sent to you@email.com ✓
```
SKILL_EOF

echo -e "${GREEN}✓ Created SKILL.md${NC}"

# ─────────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}┌─────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ✅ Setup complete!                 │${NC}"
echo -e "${BLUE}└─────────────────────────────────────┘${NC}"
echo ""
echo "What was created:"
echo "  ~/.claude/skills/end-day/SKILL.md"
echo "  ~/.claude/skills/end-day/config.json"
echo "  ~/devmaxxing/standup/"
echo "  ~/devmaxxing/reviews/daily/"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Close and reopen Claude Code (to load the new skill)"
echo "  2. Run: /end-day"
echo ""
if [[ -z "$RESEND_KEY" ]]; then
    echo -e "${BLUE}Tip: To enable email later, edit ~/.claude/skills/end-day/config.json${NC}"
    echo ""
fi
