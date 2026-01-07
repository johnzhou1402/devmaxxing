# standup-bot

For 10x engineers who don't remember everything they did yesterday B)

## Quick Start

```bash
git clone https://github.com/johnzhou1402/standup-bot.git
cd standup-bot
./setup.sh
```

## What it does

Run `/end-day` in Claude Code before you leave work:

1. **📋 Standup summary** - Leadership-friendly summaries of your PRs (no jargon)
2. **💬 PR feedback** - Extracts reviewer comments and analyzes lessons learned
3. **📧 Email digest** - Sends you a casual, emoji-rich recap (optional)

## Usage

```
/end-day          # today's PRs
/end-day ystd     # yesterday's PRs
/end-day 2026-01-05  # specific date
```

## Example Output

**Email you receive:**

```
🌙 End of Day: Tuesday, January 7

📋 What I worked on (3 PRs)

🟢 Cache plaid balances
   Ready for Review
   We can now see real-time bank balances for Plaid accounts.
   Helps with risk assessment and payout decisions.
   ⏳ Waiting on review

💬 Feedback I got (2 comments)

jacksonhuether on PR #455
   "Use decimal(10,2) for money, not float"
   💡 Takeaway: Floats cause precision errors with money.
```

**Files saved:**
- `~/devmaxxing/standup/2026-01-07.md`
- `~/devmaxxing/reviews/daily/2026-01-07.md`

## Prerequisites

- [Claude Code](https://claude.ai/code)
- [GitHub CLI](https://cli.github.com/) - `brew install gh && gh auth login`

## Setup creates

```
~/.claude/skills/end-day/
├── SKILL.md        # Instructions for Claude
└── config.json     # Email settings (optional)

~/devmaxxing/
├── standup/        # Daily standup notes
└── reviews/daily/  # PR feedback analysis
```

## Email Setup (Optional)

The setup script walks you through this, but if you want email digests:

1. Create free account at [resend.com](https://resend.com)
2. Get API key from API Keys → Create API Key
3. Set usage alerts at Settings → Alerts (recommended)

Free tier: 100 emails/day (plenty for daily digests)
